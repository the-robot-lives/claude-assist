defmodule GenAI.Model do
  @moduledoc """
  Represents a Provider Model plus picker details and encoder.
  """

  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(
    provider: nil,
    encoder: nil,
    model: nil,
    details: nil
  )

  defnodetype(
    provider: term,
    encoder: term,
    model: term,
    details: term
  )

  # ⟦𓀉𓆰𓍷𓉵⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = model_entry()
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  # ⟦𓀘𓄪𓁤𓊾⟧ inspect_custom_details :: auto-generated pointer for public function inspect_custom_details
  def inspect_custom_details(subject, opts) do
    [
      "model:", Inspect.Algebra.to_doc(subject.model, opts), ", ",
      "provider:", Inspect.Algebra.to_doc(subject.provider, opts), ", ",
      "encoder:", Inspect.Algebra.to_doc(subject.encoder, opts), ", ",
      "details:", Inspect.Algebra.to_doc(subject.details, opts), ", ",
    ]
  end
  
end

defimpl GenAI.ModelProtocol, for: [GenAI.Model] do
  # ⟦𓃡𓃀𓌽𓎃⟧ handle :: auto-generated pointer for public function handle
  def handle(subject), do: {:ok, subject.model}

  # ⟦𓌶𓀬𓀤𓌯⟧ encoder :: auto-generated pointer for public function encoder
  def encoder(subject), do: {:ok, subject.encoder || Module.concat([subject.provider, Encoder])}

  # ⟦𓃺𓀐𓋪𓌁⟧ provider :: auto-generated pointer for public function provider
  def provider(subject), do: {:ok, subject.provider}

  # ⟦𓉍𓂘𓊪𓈽⟧ name :: auto-generated pointer for public function name
  def name(subject), do: {:ok, subject.model}

  # ⟦𓁤𓁨𓎄𓎯⟧ register :: auto-generated pointer for public function register
  def register(subject, thread_context), do: {:ok, {subject, thread_context}}
end
