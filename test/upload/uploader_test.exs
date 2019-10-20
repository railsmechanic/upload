defmodule Upload.UploaderTest do
  use ExUnit.Case, async: true

  defmodule MyUploader do
    use Upload.Uploader

    def cast(file, opts \\ []) do
      with {:ok, upload} <- Upload.cast(file, opts),
           {:ok, extension} <- Upload.file_extension(upload) do
        if String.equivalent?(extension, ".txt") do
          {:ok, upload}
        else
          {:error, "Test invalid status"}
        end
      end
    end
  end

  @fixture_txt Path.expand("../fixtures/data.txt", __DIR__)
  @fixture_csv Path.expand("../fixtures/data.csv", __DIR__)

  setup do
    {status, _} = start_supervised(Upload.Adapter.Test)
    status
  end

  test "delegates by default" do
    assert {:ok, upload} = MyUploader.cast_path(@fixture_txt)
    assert {:ok, %Upload{}} = MyUploader.transfer(upload)
  end

  test "allows overriding" do
    approved = %Plug.Upload{path: @fixture_txt, filename: Path.basename(@fixture_txt)}
    unapproved = %Plug.Upload{path: @fixture_csv, filename: Path.basename(@fixture_csv)}

    assert {:ok, %Upload{}} = MyUploader.cast(approved)
    assert {:error, "Test invalid status"} = MyUploader.cast(unapproved)
  end
end
