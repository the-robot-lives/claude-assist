defmodule GenAI.Thread.State do
  @vsn 1.0
  defstruct model: [],
            tools: %{},
            settings: %{},
            model_settings: %{},
            provider_settings: %{},
            safety_settings: %{},
            messages: [],
            artifacts: %{},
            vsn: @vsn
end
