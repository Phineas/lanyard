defmodule Lanyard.KV.InterfaceTest do
  use ExUnit.Case, async: true

  alias Lanyard.KV.Interface

  test "rejects an empty key" do
    assert {:error, "key must be alphanumeric (a-zA-Z0-9_)"} = Interface.validate_pair({"", "value"})
  end

  test "accepts letters, numbers and underscores" do
    assert {:ok} = Interface.validate_pair({"valid_Key123", "value"})
  end
end
