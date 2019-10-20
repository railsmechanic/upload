defmodule Upload.Adapter.TestTest do
  use ExUnit.Case, async: true

  alias Upload.Adapter.Test, as: Adapter

  doctest Upload.Adapter.Test

  @fixture Path.expand("../../fixtures/data.txt", __DIR__)
  @upload %Upload{path: @fixture, filename: "data.txt", key: "foo/data.txt"}

  setup do
    {status, _} = start_supervised(Upload.Adapter.Test)
    status
  end

  test "stop/2" do
    assert :ok = Upload.Adapter.Test.stop()
  end

  test "put_upload/1" do
    assert :ok = Adapter.put_upload(@upload)
  end

  test "get_uploads/1" do
    assert %{} = Adapter.get_uploads()
    assert :ok = Adapter.put_upload(@upload)
    assert %{"foo/data.txt" => @upload} = Adapter.get_uploads()
  end

  test "base_url/0" do
    assert Adapter.base_url()== {:ok, System.tmp_dir()}
  end

  test "base_url!/0" do
    assert Adapter.base_url!() == System.tmp_dir()
  end

  test "get_url/1" do
    assert {:ok, "foo/bar.txt"} = Adapter.get_url("foo/bar.txt")
  end

  test "get_url!/1" do
    assert Adapter.get_url!("foo/bar.txt") == "foo/bar.txt"
  end

  test "get_signed_url/2" do
    assert {:ok, "foo/bar.txt"} = Adapter.get_signed_url("foo/bar.txt", [])
  end

  test "get_signed_url!/2" do
    assert Adapter.get_signed_url!("foo/bar.txt", []) == "foo/bar.txt"
  end

  test "transfer/1" do
    assert Adapter.get_uploads() == %{}
    assert {:ok, %Upload{key: key}} = Adapter.transfer(@upload)
    assert Map.get(Adapter.get_uploads(), key) == %Upload{@upload | transferred?: true}
  end

  test "transfer!/1" do
    assert Adapter.get_uploads() == %{}
    assert %Upload{key: key} = Adapter.transfer!(@upload)
    assert Map.get(Adapter.get_uploads(), key) == %Upload{@upload | transferred?: true}
  end
end
