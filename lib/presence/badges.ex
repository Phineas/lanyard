defmodule Lanyard.Presence.Badges do
  @moduledoc """
  Converts Discord's public user flag bitfield into stable, readable badge data.
  Only flags supplied by Discord in the Gateway user object are exposed.
  """

  import Bitwise

  @badges [
    {0, "staff", "Discord Staff"},
    {1, "partner", "Discord Partner"},
    {2, "hypesquad", "HypeSquad Events"},
    {3, "bug_hunter_level_1", "Bug Hunter Level 1"},
    {6, "hypesquad_bravery", "HypeSquad Bravery"},
    {7, "hypesquad_brilliance", "HypeSquad Brilliance"},
    {8, "hypesquad_balance", "HypeSquad Balance"},
    {9, "early_supporter", "Early Supporter"},
    {14, "bug_hunter_level_2", "Bug Hunter Level 2"},
    {16, "verified_bot_developer", "Verified Bot Developer"},
    {18, "certified_moderator", "Discord Certified Moderator"},
    {22, "active_developer", "Active Developer"}
  ]

  @doc """
  Returns known badges for a Discord public_flags bitfield.

  Unknown bits are ignored. The input may be an integer or a numeric string.
  """
  @spec from_public_flags(integer() | binary() | nil) :: [map()]
  def from_public_flags(flags) when is_binary(flags) do
    case Integer.parse(flags) do
      {value, ""} -> from_public_flags(value)
      _ -> []
    end
  end

  def from_public_flags(flags) when is_integer(flags) and flags >= 0 do
    Enum.flat_map(@badges, fn {bit, id, name} ->
      if (flags &&& (1 <<< bit)) != 0 do
        [%{id: id, name: name}]
      else
        []
      end
    end)
  end

  def from_public_flags(_), do: []
end
