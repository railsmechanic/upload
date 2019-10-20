if Code.ensure_compiled?(ExAws.S3) do
  defmodule Upload.Adapter.S3 do
    @moduledoc """
    An `Upload.Adapter` that stores files using Amazon S3.

    ### Requirements

        def deps do
          [{:ex_aws_s3, "~> 2.0"},
           {:hackney, ">= 0.0.0"},
           {:sweet_xml, ">= 0.0.0"}]
        end

    ### Configuration

        config :upload, Upload.Adapter.S3,
          bucket: "mybucket", # required
          base_url: "https://mybucket.s3.amazonaws.com" # optional

    """
    use Upload.Adapter

    @doc """
    The bucket that was configured.

    ## Examples

        iex> Upload.Adapter.S3.bucket()
        {:ok, "test-bucket-name"}

    """
    @spec bucket :: {:ok, String.t()} | {:error, String.t()}
    def bucket do
      case Upload.Config.get(__MODULE__, :bucket, :undefined) do
        bucket_name when is_binary(bucket_name) and bucket_name != "" ->
          {:ok, bucket_name}
        _invalid_bucket_name ->
          {:error, "Unable to get bucket"}
      end
    end

    @doc """
    The bucket that was configured.

    ## Examples

        iex> Upload.Adapter.S3.bucket!()
        "test-bucket-name"

    """
    @spec bucket! :: String.t() | no_return
    def bucket! do
      case bucket() do
        {:ok, bucket_name} ->
          bucket_name
        {:error, error} ->
          raise Upload.Adapter.Error, message: error
      end
    end

    @impl true
    def base_url do
      with {:ok, bucket_name} <- bucket() do
        case Upload.Config.get(__MODULE__, :base_url, "https://#{bucket_name}.s3.amazonaws.com") do
          url when is_binary(url) and url != "" ->
            {:ok, url}
          _invalid_url ->
            {:error, "Unable to get base URL"}
        end
      end
    end

    @impl true
    def base_url! do
      case base_url() do
        {:ok, aws_base_url} ->
          aws_base_url
        {:error, error} ->
          raise Upload.Adapter.Error, message: error
      end
    end

    @impl true
    def get_url(key) do
      with {:ok, aws_base_url} <- base_url() do
        url = aws_base_url
        |> URI.merge(key)
        |> URI.to_string()

        {:ok, url}
      end
    end

    @impl true
    def get_url!(key) do
      case get_url(key) do
        {:ok, url} ->
          url
        {:error, error} ->
          raise Upload.Adapter.Error, message: error
      end
    end

    @impl true
    def get_signed_url(key, opts \\ []) do
      with {:ok, bucket_name} <- bucket() do
        :s3
        |> ExAws.Config.new()
        |> ExAws.S3.presigned_url(:get, bucket_name, key, opts)
      end
    end

    @impl true
    def get_signed_url!(key, opts \\ []) do
      case get_signed_url(key, opts) do
        {:ok, signed_url} ->
          signed_url
        {:error, error} ->
          raise Upload.Adapter.Error, message: error
      end
    end

    @impl true
    def transfer(%Upload{key: key, path: path} = upload) do
      case put_object(key, path) do
        {:ok, _response} ->
          {:ok, %Upload{upload | transferred?: true}}
        {:error, {:http_error, http_status, binary}} ->
          {:error, "Unable to transfer object - #{http_status}: #{binary}"}
        _error ->
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
    @spec put_object(String.t(), String.t()) :: ExAws.Request.t()
    defp put_object(key, path)
      when is_binary(key) and key != ""
      when is_binary(path) and path != "" do
        with {:ok, bucket_name} <- bucket() do
          path
          |> ExAws.S3.Upload.stream_file()
          |> ExAws.S3.upload(bucket_name, key)
          |> ExAws.request()
        end
    end
    defp put_object(_key, _path), do: {:error, "Unable to transfer object due to invalid parameters"}
  end
end
