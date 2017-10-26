defmodule Upload do
  @moduledoc """
  An opinionated file uploader.
  """

  @enforce_keys [:key, :path, :filename]
  defstruct [:key, :path, :filename, status: :pending]

  @config Application.get_env(:upload, __MODULE__, [adapter: Upload.Adapters.Local])
  @adapter Keyword.get(@config, :adapter)

  @type t :: %Upload{
    key: String.t,
    filename: String.t,
    path: String.t
  }

  @type transferred :: %Upload{
    key: String.t,
    filename: String.t,
    path: String.t,
    status: :transferred
  }

  @type uploadable :: Plug.Upload.t | Upload.t
  @type uploadable_path :: String.t | Upload.t

  @spec get_url(String.t) :: String.t
  defdelegate get_url(key), to: @adapter

  @spec transfer(Upload.t) :: {:ok, Upload.transferred} | {:error, any}
  defdelegate transfer(upload), to: @adapter

  @doc """
  Normalizes an uploadable dataum into something we can transfer.
  """
  @spec cast(uploadable, list) ::
    {:ok, Upload.t} | {:error, String.t | :not_uploadable}
  def cast(uploadable, opts \\ [])
  def cast(%Upload{} = upload, _opts), do: {:ok, upload}
  def cast(%Plug.Upload{filename: filename, path: path}, opts) do
    do_cast(filename, path, opts)
  end
  def cast(_not_uploadable, _opts) do
    {:error, :not_uploadable}
  end

  @doc """
  Cast a file path to an `%Upload{}`.

  *Warning:* Do not use `cast_path` with unsanitized user input.
  """
  @spec cast_path(uploadable_path, list) ::
    {:ok, Upload.t} | {:error, String.t | :not_uploadable}
  def cast_path(path, opts \\ [])
  def cast_path(%Upload{} = upload, _opts), do: upload
  def cast_path(path, opts) when is_binary(path) do
    path
    |> Path.basename
    |> do_cast(path, opts)
  end
  def cast_path(_, _opts) do
    {:error, :not_uploadable}
  end

  defp do_cast(filename, path, opts) do
    {:ok, %__MODULE__{
      key: generate_key(filename, opts),
      path: path,
      filename: filename,
      status: :pending
    }}
  end

  @doc """
  Converts a filename to a unique key.

  ## Examples

      iex> Upload.generate_key("phoenix.png")
      "b9452178-9a54-5e99-8e64-a059b01b88cf.png"

      iex> Upload.generate_key("phoenix.png", prefix: ["logos"])
      "logos/b9452178-9a54-5e99-8e64-a059b01b88cf.png"

  """
  @spec generate_key(String.t, [{:prefix, list}]) :: String.t
  def generate_key(filename, opts \\ []) when is_binary(filename) do
    uuid = UUID.uuid4(:hex)
    ext  = get_extension(filename)

    opts
    |> Keyword.get(:prefix, [])
    |> Path.join(uuid <> ext)
  end

  @doc """
  Gets the extension from a filename.

  ## Examples

      iex> Upload.get_extension("foo.png")
      ".png"

      iex> Upload.get_extension("foo.PNG")
      ".png"

      iex> Upload.get_extension("foo")
      ""

      iex> {:ok, upload} = Upload.cast_path("/path/to/foo.png")
      ...> Upload.get_extension(upload)
      ".png"

  """
  @spec get_extension(String.t | Upload.t) :: String.t
  def get_extension(%Upload{filename: filename}) do
    get_extension(filename)
  end
  def get_extension(filename) when is_binary(filename) do
    filename |> Path.extname |> String.downcase
  end
end
