defmodule Upload.Adapter.FakeTest do
  use ExUnit.Case, async: true
  doctest Upload.Adapter.Fake

  alias Upload.Adapter.Fake, as: Adapter

  @fixture Path.expand("../../fixtures/data.txt", __DIR__)
  @upload %Upload{path: @fixture, filename: "data.txt", key: "foo/data.txt"}

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
    assert {:ok, %Upload{transferred?: true}} = Adapter.transfer(@upload)
  end

  test "transfer!/1" do
    assert %Upload{transferred?: true} = Adapter.transfer!(@upload)
  end
end
