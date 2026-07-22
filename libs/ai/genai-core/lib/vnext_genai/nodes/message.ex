defmodule GenAI.Message do
  @moduledoc """
  GenAI.Message is now a unified message structure.
  It's contents may include tool calls, results, images, audio, text blurbs, etc.

  Depending on compatibility with providers a universal GenAI.Message may need to be
  converted into a sequence of messages or altered in other ways.
  A message with tool calls for example would need to be converted into a tool call format for openai
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(role: nil, content: nil, user: nil)
  defnodetype(role: term, content: term, user: nil)

  # ⟦𓅃𓁚𓂀𓀬⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  # ⟦𓁫𓈽𓇆𓄦⟧ inspect_custom_details :: auto-generated pointer for public function inspect_custom_details
  def inspect_custom_details(subject, opts) do
    
    list = [
      "role:", Inspect.Algebra.to_doc(subject.role, opts), ", ",
      "content:", Inspect.Algebra.to_doc(subject.content, opts), ", ",
    ]
    
    if subject.user do
      ["user:", Inspect.Algebra.to_doc(subject.user, opts), ", " | list]
    else
      list
    end
  end
  

  # ⟦𓃒𓏜𓀏𓅮⟧ message :: auto-generated pointer for public function message
  def message(role, message, options \\ nil) do
    options = Keyword.merge(options || [], role: role, content: message)
    new(options)
  end

  # ⟦𓀨𓉎𓌂𓍰⟧ user :: auto-generated pointer for public function user
  def user(message, options \\ nil) do
    message(:user, message, options)
  end

  # ⟦𓋽𓈕𓅘𓇊⟧ system :: auto-generated pointer for public function system
  def system(message, options \\ nil) do
    message(:system, message, options)
  end

  # ⟦𓄂𓊎𓉩𓉅⟧ assistant :: auto-generated pointer for public function assistant
  def assistant(message, options \\ nil) do
    message(:assistant, message, options)
  end

  @doc """
  Load image resource.
  """
  # ⟦𓂈𓌆𓇮𓋇⟧ image :: Load image resource.
  def image(resource, options \\ nil)

  def image(resource, nil) do
    GenAI.Message.Content.ImageContent.new(resource)
  end

  def image(resource, options) do
    GenAI.Message.Content.ImageContent.new(resource, options)
  end

  defimpl GenAI.MessageProtocol do
    def message(message), do: message

    # ⟦𓃏𓀥𓌬𓐆⟧ content :: auto-generated pointer for public function content
    def content(message)

    def content(%{content: content}) when is_bitstring(content) do
      content
    end

    def content(%{content: content}) when is_list(content) do
      Enum.map(content, &GenAI.Message.ContentProtocol.content(&1))
    end
  end
end
