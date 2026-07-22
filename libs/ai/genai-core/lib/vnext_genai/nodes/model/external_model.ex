defmodule GenAI.ExternalModel do
  @vsn 1.0
  
  
  require GenAI.Records.Directive
  import GenAI.Records.Directive
  
  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  
  @enforce_keys [:resource_handle, :manager]
  defnodestruct(
    resource_handle: nil,
    manager: nil,
    external: nil,
    configuration: nil,
    
    provider: nil,
    encoder: nil,
    model: nil,
    details: nil
  )
  
  defnodetype(
    resource_handle: term,
    manager: term,
    external: term,
    configuration: term,
    
    provider: term,
    encoder: term,
    model: term,
    details: term
  )
  
  # ⟦𓁧𓁜𓅮𓋣⟧ do_node_type :: auto-generated pointer for public function do_node_type
  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Model}
  
  # ⟦𓈎𓐊𓁵𓍉⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)
  
  def apply_node_directives(this, _, _, session, context, options) do
    entry = model_entry()
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  
  
  
  
  
  defimpl GenAI.ModelProtocol do
    # ⟦𓈥𓅒𓍣𓅲⟧ handle :: auto-generated pointer for public function handle
    def handle(subject), do: {:ok, subject.resource_handle}
    # ⟦𓏱𓁨𓈚𓂋⟧ encoder :: auto-generated pointer for public function encoder
    def encoder(subject), do: {:ok, subject.encoder || Module.concat([subject.provider, Encoder])}
    # ⟦𓋺𓈧𓂬𓃽⟧ provider :: auto-generated pointer for public function provider
    def provider(subject), do: {:ok, subject.provider}
    # ⟦𓆇𓉐𓋅𓄳⟧ name :: auto-generated pointer for public function name
    def name(subject), do: {:ok, subject.model}
    # ⟦𓋺𓂭𓍙𓐗⟧ register :: auto-generated pointer for public function register
    def register(subject, thread_context), do: {:ok, {subject, thread_context}}
  end
  
end