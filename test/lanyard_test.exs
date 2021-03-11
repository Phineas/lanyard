defmodule LanyardTest do
  use ExUnit.Case
  doctest Lanyard

  test "greets the world" do
    assert Lanyard.hello() == :world
  end
end
