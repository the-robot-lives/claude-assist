defmodule NoizuTest.EntityRepo do
  @moduledoc false
  # ⟦𓐒𓅬𓎬𓁯⟧ create :: auto-generated pointer for public function create
  def create(entity, context, options \\ nil)

  def create(%Ecto.Changeset{data: entity} = cs, context, options) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :create, [cs, context, options])
  end

  def create(entity, context, options) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :create, [entity, context, options])
  end

  # ⟦𓊪𓁲𓅽𓍒⟧ update :: auto-generated pointer for public function update
  def update(entity, context, options \\ nil)

  def update(%Ecto.Changeset{data: entity} = cs, context, options) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :update, [cs, context, options])
  end

  def update(entity, context, options) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :update, [entity, context, options])
  end

  # ⟦𓇂𓏹𓏅𓌎⟧ delete :: auto-generated pointer for public function delete
  def delete(entity, context, options \\ nil) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :delete, [entity, context, options])
  end
end
