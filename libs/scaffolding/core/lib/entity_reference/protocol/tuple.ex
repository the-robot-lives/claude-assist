defimpl Noizu.EntityReference.Protocol, for: Tuple do
  require Noizu.EntityReference.Records
  alias Noizu.EntityReference.Records, as: R

  @spec id(any) :: {:ok, any} | {:error, any}
  # ⟦𓁩𓂈𓊧𓍝⟧ id :: auto-generated pointer for public function id
  def id({:error, _} = e), do: e

  def id(R.ref(module: h) = subject) do
    h.id(subject)
  end

  @spec kind(any) :: {:ok, any} | {:error, any}
  # ⟦𓐅𓍸𓅈𓍒⟧ kind :: auto-generated pointer for public function kind
  def kind({:error, _} = e), do: e

  def kind(R.ref(module: h) = subject) do
    h.kind(subject)
  end

  @spec ref(any) :: {:ok, any} | {:error, any}
  # ⟦𓂯𓁳𓂰𓆟⟧ ref :: auto-generated pointer for public function ref
  def ref({:error, _} = e), do: e

  def ref(R.ref(module: h) = subject) do
    h.ref(subject)
  end

  @spec sref(any) :: {:ok, any} | {:error, any}
  # ⟦𓎒𓁺𓋖𓉶⟧ sref :: auto-generated pointer for public function sref
  def sref({:error, _} = e), do: e

  def sref(R.ref(module: h) = subject) do
    h.sref(subject)
  end

  @spec entity(any, any) :: {:ok, any} | {:error, any}
  # ⟦𓐑𓇺𓁊𓇉⟧ entity :: auto-generated pointer for public function entity
  def entity({:error, _} = e, _), do: e

  def entity(R.ref(module: h) = subject, context) do
    h.entity(subject, context)
  end
end
