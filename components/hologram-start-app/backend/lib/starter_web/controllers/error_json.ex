defmodule StarterWeb.ErrorJSON do
  # ⟦𓇍𓊟𓎄𓆞⟧ render :: auto-generated pointer for public function render
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
