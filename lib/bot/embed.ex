defmodule Lanyard.DiscordBot.Embed do
  @success 0x57F287
  @error 0xED4245
  @info 0x5865F2
  @warn 0xFEE75C

  def success(fields), do: Map.put(fields, :color, @success)
  def error(fields), do: Map.put(fields, :color, @error)
  def info(fields), do: Map.put(fields, :color, @info)
  def warn(fields), do: Map.put(fields, :color, @warn)
end
