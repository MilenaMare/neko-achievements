defmodule Neko.Rules.BasicRule do
  @behaviour Neko.Rules.Rule

  defstruct ~w(
    neko_id
    level
    threshold
    next_threshold
  )a

  use ExConstructor, atoms: true, strings: true

  def achievements(user_id) do
    value = value(user_id)

    rules()
    |> Enum.filter(&rule_applies?(&1, value))
    |> Enum.map(&build_achievement(&1, user_id, value))
  end

  defp value(user_id) do
    {:ok, store_pid} = Neko.UserRate.Store.Registry.lookup(user_id)

    store_pid
    |> Neko.UserRate.Store.all()
    |> MapSet.size()
  end

  defp rules do
    Neko.Rules.BasicRule.Store.all()
  end

  defp rule_applies?(rule, value) do
    value >= rule.threshold
  end

  defp build_achievement(rule, user_id, value) do
    %Neko.Achievement{
      user_id: user_id,
      neko_id: rule.neko_id,
      level: rule.level,
      progress: progress(rule, value)
    }
  end

  # TODO
  defp progress(%{next_threshold: nil}, _value) do
    100
  end
  defp progress(rule, value) do
    %{threshold: threshold, next_threshold: next_threshold} = rule
    ((value - threshold) / (next_threshold - threshold)) * 100 |> round()
  end
end