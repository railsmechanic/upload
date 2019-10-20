defmodule Upload do
  @moduledoc """
  An opinionated file uploader.
  """

  ## - Module attributes
  @adapter Upload.Config.get(__MODULE__, :adapter, Upload.Adapter.Local)

  ## - Struct data
  @enforce_keys [:key, :path, :filename]
  defstruct [:key, :path, :filename, transferred?: false]

  ## - Type definitions
  @type t :: %__MODULE__{
          key: String.t(),
          path: String.t(),
          filename: String.t(),
          transferred?: boolean()
        }
  @type uploadable :: Plug.Upload.t() | __MODULE__.t()
  @type uploadable_path :: Path.t() | String.t()

  @doc """
  Get the URL for a given key. It will behave differently based
  on the adapter you're using.

  ### Local
      iex> Upload.get_url("123456.png")
      "/uploads/123456.png"

  ### S3
      iex> Upload.get_url("123456.png")
      "https://test-bucket-name.s3.amazonaws.com/123456.png"

  ### Fake / Test
      iex> Upload.get_url("123456.png")
      "123456.png"
  """
  @spec get_url(__MODULE__.t() | String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_url(%__MODULE__{key: key}), do: get_url(key)
  def get_url(key) when is_binary(key) and key != "", do: @adapter.get_url(key)
  def get_url(_key), do: {:error, "Unable to get URL"}

  @doc """
  Get the URL for a given key. It will behave differently based
  on the adapter you're using.

  ## Examples
      iex> Upload.get_signed_url(%Upload{key: "123456.png"})
      {:ok, "http://yoururl.com/123456.png?X-Amz-Expires=3600..."}

      iex> Upload.get_signed_url("123456.png")
      {:ok, "http://yoururl.com/123456.png?X-Amz-Expires=3600..."}

      iex> Upload.get_signed_url("123456.png", expires_in: 4200)
      {:ok, "http://yoururl.com/123456.png?X-Amz-Expires=4200..."}

      iex> Upload.get_signed_url(123)
      {:error, "Unable to get signed URL"}
  """
  @spec get_signed_url(__MODULE__.t() | String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_signed_url(upload, opts \\ [])
  def get_signed_url(%__MODULE__{key: key}, opts), do: get_signed_url(key, opts)
  def get_signed_url(key, opts) when is_binary(key) and key != "", do: @adapter.get_signed_url(key, opts)
  def get_signed_url(_key, _opts), do: {:error, "Unable to get signed URL"}

  @doc """
  Transfer a file according to its configured adapter.

  ## Examples
      iex> Upload.transfer(%Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"})
      {:ok, "%Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"}}

      iex> Upload.transfer(nil)
      {:error, "Given data is not uploadable"}
  """
  @spec transfer(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def transfer(%__MODULE__{} = upload), do: @adapter.transfer(upload)
  def transfer(_not_uploadable), do: {:error, "Unable to upload given data"}

  @doc """
  Casts a `Plug.Upload` to an `Upload`.

  ## Examples
      iex> Upload.cast(%Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"})
      {:ok, %Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"}}

      iex> Upload.cast(%Plug.Upload{path: "/path/to/foo.png", filename: "foo.png"})
      {:ok, %Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"}}

      iex> Upload.cast(100)
      {:error, "Unable to cast to an uploadable"}
  """
  @spec cast(uploadable, list) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def cast(uploadable, opts \\ [])
  def cast(%__MODULE__{} = upload, _opts), do: {:ok, upload}
  def cast(%Plug.Upload{path: path, filename: filename}, opts), do: do_cast(path, [{:filename, filename} | opts])
  def cast(_uploadable, _opts), do: {:error, "Unable to cast to an uploadable"}

  @doc """
  Cast a file path to an `Upload`.

  *Warning:* Do not use `cast_path` with unsanitized user input.

  ## Examples
      iex> Upload.cast_path(%Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"})
      {:ok, %Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"}}

      iex> Upload.cast_path("/path/to/foo.png")
      {:ok, %Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"}}

      iex> Upload.cast_path(100)
      {:error, "Unable to cast to an uploadable"}
  """
  @spec cast_path(uploadable_path, list) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def cast_path(path, opts \\ [])
  def cast_path(%__MODULE__{} = upload, _opts), do: {:ok, upload}
  def cast_path(path, opts) when is_binary(path), do: do_cast(path, opts)
  def cast_path(_uploadable_path, _opts), do: {:error, "Unable to cast to an uploadable"}

  @doc """
  Gets the extension from a filename.

  ## Examples
      iex> Upload.file_extension(%Upload{path: "/path/to/foo.png", filename: "foo.png", key: "123456.png"})
      {:ok, ".png"}

      iex> Upload.file_extension(%Plug.Upload{path: "/path/to/foo.png", filename: "foo.png"})
      {:ok, ".png"}

      iex> Upload.file_extension("foo.png")
      {:ok, ".png"}

      iex> Upload.file_extension("foo.PNG")
      {:ok, ".png"}

      iex> Upload.file_extension("foo")
      {:ok, ""}

      iex> Upload.file_extension(123)
      {:error, "Unable to determine file extension"}
  """
  @spec file_extension(__MODULE__.t() | Plug.Upload.t() | String.t()) :: {:ok, String.t()} | {:error,String.t()}
  def file_extension(%__MODULE__{filename: filename}), do: file_extension(filename)
  def file_extension(%Plug.Upload{filename: filename}), do: file_extension(filename)
  def file_extension(filename) do
    case sanitize_filename(filename) do
      {:ok, filename} ->
        extension = filename
        |> Path.extname()
        |> String.downcase()
        {:ok, extension}
      _error ->
        {:error, "Unable to determine file extension"}
    end
  end

  ## - Helper functions
  @spec do_cast(uploadable_path, Keyword.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  defp do_cast(path, [{:filename, filename} | opts]) do
    with {:ok, path} <- sanitize_path(path),
         {:ok, filename} <- sanitize_filename(filename),
         {:ok, key} <- file_key(filename, opts)
    do
      {:ok,
        %__MODULE__{
          path: path,
          filename: filename,
          key: key,
        }
      }
    end
  end
  defp do_cast(path, opts) when is_binary(path), do: do_cast(path, [{:filename, Path.basename(path)} | opts])
  defp do_cast(_path, _opts), do: {:error, "Unable to cast to an uploadable"}

  @spec generate_identifier :: {:ok, String.t()}
  defp generate_identifier, do: {:ok, UUID.uuid4(:hex)}

  @spec file_key(String.t(), [{:prefix, list(String.t())}]) :: {:ok, String.t()} | {:error, String.t()}
  defp file_key(filename, opts) do
    with {:ok, filename} <- sanitize_filename(filename),
         {:ok, extension} <- file_extension(filename),
         {:ok, identifier} <- generate_identifier() do
      key = opts
      |> Keyword.get(:prefix, [])
      |> Path.join("/")
      |> Path.join(identifier <> extension)

      {:ok, key}
    end
  end

  @spec sanitize_filename(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp sanitize_filename(filename) when is_binary(filename) do
    trimmed_filename = String.trim(filename)

    if String.length(trimmed_filename) > 0 do
      {:ok, trimmed_filename}
    else
      {:error, "Filename is an empty string"}
    end
  end
  defp sanitize_filename(_filename), do: {:error, "Filename is invalid"}

  @spec sanitize_path(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp sanitize_path(path) when is_binary(path) do
    trimmed_path = String.trim(path)

    cond do
      String.length(trimmed_path) <= 0 ->
        {:error, "Path is an empty string"}
      File.exists?(trimmed_path) == false ->
        {:error, "Path does not exist"}
      true ->
        {:ok, trimmed_path}
    end
  end
  defp sanitize_path(_path), do: {:error, "Path is invalid"}
end
