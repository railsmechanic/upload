defmodule Upload.Adapter.LocalTest do
  use ExUnit.Case, async: true

  doctest Upload.Adapter.Local

  alias Upload.Adapter.Local, as: Adapter

  @fixture Path.expand("../../fixtures/data.txt", __DIR__)
  @upload %Upload{path: @fixture, filename: "data.txt", key: "foo/data.txt"}

  setup do
    {result, _} = File.rm_rf(Adapter.storage_path!())
    result
  end

  test "storage_path/0" do
    assert {:ok, "priv/static/uploads"} = Adapter.storage_path()
  end

  test "storage_path!/0" do
    assert Adapter.storage_path!() == "priv/static/uploads"
  end

  test "base_url/0" do
    assert {:ok, "/uploads"} = Adapter.base_url()
  end

  test "base_url!/0" do
    assert Adapter.base_url!() == "/uploads"
  end

  test "get_url/1" do
    assert {:ok, "/uploads/foo.txt"} = Adapter.get_url("foo.txt")
    assert {:ok, "/uploads/foo/bar.txt"} = Adapter.get_url("foo/bar.txt")
  end

  test "get_url!/1" do
    assert Adapter.get_url!("foo.txt") == "/uploads/foo.txt"
    assert Adapter.get_url!("foo/bar.txt") == "/uploads/foo/bar.txt"
  end

  test "get_signed_url/2" do
    assert {:ok, "/uploads/foo.txt"} = Adapter.get_signed_url("foo.txt", [])
    assert {:ok, "/uploads/foo/bar.txt"} = Adapter.get_signed_url("foo/bar.txt", [])
  end

  test "get_signed_url!/2" do
    assert Adapter.get_signed_url!("foo.txt", []) == "/uploads/foo.txt"
    assert Adapter.get_signed_url!("foo/bar.txt", []) == "/uploads/foo/bar.txt"
  end

  test "transfer/1" do
    assert {:ok, %Upload{key: key, transferred?: true}} = Adapter.transfer(@upload)
    Adapter.storage_path!()
    |> Path.join(key)
    |> File.exists?()
    |> assert
  end

  test "transfer!/1" do
    assert %Upload{key: key, transferred?: true} = Adapter.transfer!(@upload)
    Adapter.storage_path!()
    |> Path.join(key)
    |> File.exists?()
    |> assert
  end
end
