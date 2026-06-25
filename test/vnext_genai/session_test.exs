defmodule GenAI.VNext.SessionTest do
  use ExUnit.Case,
    async: true

  @moduletag :session

  describe "GenAI.Thread.Session Acceptance Tests" do
    test "Setup Session Thread" do
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(model)
        |> GenAI.with_setting(:temperature, 0.5)
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_message(GenAI.Message.user("Hello"))

      assert thread.__struct__ == GenAI.Thread.Session

      {:ok, {response, _}} =
        thread
        |> GenAI.run(context)

      %GenAI.ChatCompletion{choices: [choice | _]} = response

      assert choice.message.content == "I'm afraid I can't do that Dave."
    end

    # End Setup Test
  end

  # End Acceptance Tests
end
