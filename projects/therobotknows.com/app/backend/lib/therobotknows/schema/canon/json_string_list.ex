defmodule Therobotknows.Schema.Canon.JsonStringList do
  @moduledoc false
  use Ecto.Type

  def type, do: :any

  def cast(list) when is_list(list), do: {:ok, list}
  def cast(_), do: :error

  def load(list) when is_list(list), do: {:ok, list}
  def load(_), do: {:ok, []}

  def dump(list) when is_list(list), do: {:ok, list}
  def dump(_), do: :error
end

