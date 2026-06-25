defmodule GenAITest do
  # import GenAI.Test.Support.Common
  use ExUnit.Case
  doctest GenAI
  doctest GenAI.Helpers
  
  describe "Streaming Support" do
  
   @tag :skip
   test "Default Streaming Policy - Session" do
     context = Noizu.Context.system()
     model = GenAI.Support.TestProvider.Models.model_one()
     
     thread =
       GenAI.chat(:session)
       |> GenAI.with_model(model)
       |> GenAI.with_setting(:temperature, 0.5)
       |> GenAI.with_message(GenAI.Message.system("System Prompt"))
       |> GenAI.with_message(GenAI.Message.user("Hello"))
     {:ok, {acc, _}} = GenAI.stream(thread, context)
     assert acc.__struct__ == GenAI.StreamHandler.Default.Accumulator
   end
   
   @tag :skip
   test "Default Streaming Policy - Legacy" do
     context = Noizu.Context.system()
     model = GenAI.Support.TestProvider.Models.model_one()
     
     thread =
       GenAI.chat(:standard)
       |> GenAI.with_model(model)
       |> GenAI.with_setting(:temperature, 0.5)
       |> GenAI.with_message(GenAI.Message.system("System Prompt"))
       |> GenAI.with_message(GenAI.Message.user("Hello"))
       #|> GenAI.with_stream_handler(GenAI.StreamHandler.Console)
     {:ok, {acc, _}} = GenAI.stream(thread, context)
     assert acc.__struct__ == GenAI.StreamHandler.Default.Accumulator
   end
   
  end
  
  
  
  
end
