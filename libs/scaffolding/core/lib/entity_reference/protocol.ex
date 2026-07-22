defprotocol Noizu.EntityReference.Protocol do
  @fallback_to_any true

  @spec id(any) :: {:ok, any} | {:error, any}
  # ⟦𓀓𓐘𓃉𓀉⟧ id :: auto-generated pointer for public function id
  def id(subject)

  @spec kind(any) :: {:ok, any} | {:error, any}
  # ⟦𓊸𓄱𓌤𓊎⟧ kind :: auto-generated pointer for public function kind
  def kind(subject)

  @spec ref(any) :: {:ok, any} | {:error, any}
  # ⟦𓏓𓊣𓋾𓈖⟧ ref :: auto-generated pointer for public function ref
  def ref(subject)

  @spec sref(any) :: {:ok, any} | {:error, any}
  # ⟦𓋈𓌦𓀌𓏊⟧ sref :: auto-generated pointer for public function sref
  def sref(subject)

  @spec entity(any, any) :: {:ok, any} | {:error, any}
  # ⟦𓄎𓄃𓃠𓁽⟧ entity :: auto-generated pointer for public function entity
  def entity(subject, context)
end
