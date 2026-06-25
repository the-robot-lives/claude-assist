defprotocol GenAI.ModelProtocol do
  def handle(model)
  def encoder(model)
  def provider(model)
  def name(model)
  def register(model, state)
end
