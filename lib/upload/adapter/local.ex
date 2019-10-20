defmodule Upload.Adapter.Local do
  @moduledoc """
  An `Upload.Adapter` that saves files to disk.

  ### Configuration

      config :upload, Upload.Adapter.Local,
        base_url: "/uploads", # optional
        storage_path: "priv/static/uploads" # optional

  """
  use Upload.Adapter

  @doc """
  Path where files are stored. Defaults to `priv/static/uploads`.

  ## Examples

      iex> Upload.Adapter.Local.storage_path()
      {:ok, "priv/static/uploads"}

  """
  @spec storage_path :: {:ok, String.t()} | {:error, String.t()}
  def storage_path do
    case Upload.Config.get(__MODULE__, :storage_path, "priv/static/uploads") do
      storage when is_binary(storage) and storage != "" ->
        {:ok, storage}
      _error ->
        {:error, "Unable to get storage path"}
    end
  end

  @doc """
  Path where files are stored. Defaults to `priv/static/uploads`.

  ## Examples

      iex> Upload.Adapter.Local.storage_path!()
      "priv/static/uploads"

  """
  @spec storage_path! :: String.t() | no_return
  def storage_path! do
    case storage_path() do
      {:ok, storage} ->
        storage
      {:error, error} ->
        raise Upload.Adapter.Error, message: error
    end
  end

  @impl true
  def base_url do
    case Upload.Config.get(__MODULE__, :base_url, "/uploads") do
      url when is_binary(url) and url != "" ->
        {:ok, url}
      _error ->
        {:error, "Unable to get base URL"}
    end
  end

  @impl true
  def base_url! do
    case base_url() do
      {:ok, url} ->
        url
      {:error, error} ->
        raise Upload.Adapter.Error, message: error
    end
  end

  @impl true
  def get_url(key) do
    with {:ok, local_base_url} <- base_url(),
         {:ok, joined_url} <- join_url(local_base_url, key)
    do
      {:ok, joined_url}
    end
  end

  @impl true
  def get_url!(key) do
    case get_url(key) do
      {:ok, joined_url} ->
        joined_url
      {:error, error} ->
        raise Upload.Adapter.Error, message: error
    end
  end

  @impl true
  def get_signed_url(key, _opts), do: get_url(key)

  @impl true
  def get_signed_url!(key, _opts), do: get_url!(key)

  @impl true
  def transfer(%Upload{key: key, path: path} = upload) do
    with {:ok, local_storage_path} <- storage_path(),
         filename when is_binary(filename) and filename != "" <- Path.join(local_storage_path, key),
         directory when is_binary(directory) and directory != "" <- Path.dirname(filename),
         :ok <- File.mkdir_p(directory),
         :ok <- File.cp(path, filename)
    do
      {:ok, %Upload{upload | transferred?: true}}
    else
      {:error, error} ->
        {:error, "Unable to transfer object: #{error}"}
      _unknown_error ->
        {:error, "Unable to transfer object due to an unknown error"}
    end
  end

  @impl true
  def transfer!(%Upload{} = upload) do
    case transfer(upload) do
      {:ok, upload_result} ->
        upload_result
      {:error, error} ->
        raise Upload.Adapter.Error, message: error
    end
  end

  ## - Helper functions
  @spec join_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp join_url(a, b)
    when is_binary(a)
    when is_binary(b)
  do
    case "#{String.trim_trailing(a, "/")}/#{String.trim_leading(b, "/")}" do
      url_string when byte_size(url_string) > 1 ->
        {:ok, url_string}
      _invalid_url_string ->
        {:error, "Unable to join URL"}
    end
  end
  defp join_url(_a, _b), do: {:error, "Unable to join URL"}
end
