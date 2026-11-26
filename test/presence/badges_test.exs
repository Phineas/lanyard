defmodule Lanyard.Presence.BadgesTest do
  use ExUnit.Case, async: true
  import Bitwise

  alias Lanyard.Presence.Badges

  test "returns every recognized badge represented in public flags" do
    flags = (1 <<< 0) ||| (1 <<< 2) ||| (1 <<< 9) ||| (1 <<< 22)

    assert Badges.from_public_flags(flags) == [
             %{id: "staff", name: "Discord Staff"},
             %{id: "hypesquad", name: "HypeSquad Events"},
             %{id: "early_supporter", name: "Early Supporter"},
             %{id: "active_developer", name: "Active Developer"}
           ]
  end

  test "accepts numeric strings" do
    assert Badges.from_public_flags("512") == [
             %{id: "early_supporter", name: "Early Supporter"}
           ]
  end

  test "returns an empty list for missing, invalid, negative, or unknown flags" do
    assert Badges.from_public_flags(nil) == []
    assert Badges.from_public_flags("not-a-number") == []
    assert Badges.from_public_flags(-1) == []
    assert Badges.from_public_flags(1 <<< 30) == []
  end
end
