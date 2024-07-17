defmodule PetalCliTest do
  use ExUnit.Case
  doctest PetalCli

  test "greets the world" do
    assert PetalCli.hello() == :world
  end
end
