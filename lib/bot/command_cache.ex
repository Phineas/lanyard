defmodule Lanyard.DiscordBot.CommandCache do
  @table :slash_commands

  def init do
    :ets.new(@table, [:named_table, :set, :public])
  end

  def put_many(commands) when is_list(commands) do
    Enum.each(commands, fn
      %{"name" => name, "id" => id} -> :ets.insert(@table, {name, id})
      _ -> :ok
    end)
  end

  def get_id(name) do
    case :ets.lookup(@table, name) do
      [{^name, id}] -> id
      _ -> nil
    end
  rescue
    ArgumentError -> nil
  end

  def mention(name) do
    case get_id(name) do
      nil -> "`/#{name}`"
      id -> "</#{name}:#{id}>"
    end
  end
end
