defmodule Upload.Adapter.Test do
  use Upload.Adapter
  use Agent

  @moduledoc """
  An `Upload.Adapter` that keeps track of uploaded files in memory, so that
  you can make assertions.

  ### Example

      test "files are uploaded" do
        assert {:ok, _} = start_supervised(Upload.Adapter.Test)
        assert {:ok, upload} = Upload.cast_path("/path/to/file.txt")
        assert {:ok, upload} = Upload.transfer(upload)
        assert Map.size(Upload.Adapter.Test.get_uploads()) == 1
      end

  """

  @doc """
  Starts and agent for the test adapter.
  """
  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stops the agent for the test adapter.
  """
  def stop(reason \\ :normal, timeout \\ :infinity) do
    Agent.stop(__MODULE__, reason, timeout)
  end

  @doc """
  Get all uploads.
  """
  def get_uploads do
    Agent.get(__MODULE__, fn state -> state end)
  end

  @doc """
  Add an upload to the state.
  """
  def put_upload(upload) do
    Agent.update(__MODULE__, &Map.put(&1, upload.key, upload))
  end

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
  def transfer(%Upload{} = upload) do
    upload = %Upload{upload | transferred?: true}
    put_upload(upload)
    {:ok, upload}
  end

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
