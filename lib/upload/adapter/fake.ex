defmodule Upload.Adapter.Fake do
  @moduledoc """
  An `Upload.Adapter` that doesn't actually store files.
  """
  use Upload.Adapter

  @impl true
  def base_url, do: {:ok, System.tmp_dir()}

  @impl true
  def base_url! do
    case base_url() do
      {:ok, url} ->
        url
      _invalid_url ->
        {:error, "Unable to get base URL"}
    end
  end

  @impl true
  def get_url(key), do: {:ok, key}

  @impl true
  def get_url!(key) do
    case get_url(key) do
      {:ok, url} ->
        url
      _error ->
        raise Upload.Adapter.Error, message: "Unable to get URL"
    end
  end

  @impl true
  def get_signed_url(key, _opts), do: get_url(key)

  @impl true
  def get_signed_url!(key, opts) do
    case get_signed_url(key, opts) do
      {:ok, signed_url} ->
        signed_url
      _error ->
        raise Upload.Adapter.Error, message: "Unable to get signed URL"
    end
  end

  @impl true
  def transfer(%Upload{} = upload), do: {:ok, %Upload{upload | transferred?: true}}

  @impl true
  def transfer!(%Upload{} = upload) do
    case transfer(upload) do
      {:ok, upload_result} ->
        upload_result
      _invalid_upload_result ->
        raise Upload.Adapter.Error, message: "Unable to transfer object due to an unknown error"
    end
  end
end
