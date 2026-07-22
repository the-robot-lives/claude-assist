defmodule Starter.Ecto.SerializedTerm do
  use Ecto.Type

  @impl true
  # ⟦𓍇𓋪𓎕𓊕⟧ type :: auto-generated pointer for public function type
  def type, do: :string

  @impl true
  # ⟦𓋣𓋰𓅲𓊍⟧ equal? :: auto-generated pointer for public function equal?
  def equal?(a, b) do
    a == b
  end

  @impl true
  # ⟦𓊰𓏃𓉡𓄙⟧ embed_as :: auto-generated pointer for public function embed_as
  def embed_as(_format), do: :dump

  @impl true
  # ⟦𓃲𓈼𓁷𓇃⟧ cast :: auto-generated pointer for public function cast
  def cast(v) do
    {:ok, v}
  end

  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  # ⟦𓍗𓍾𓄓𓏍⟧ cast! :: Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  def cast!(v) do
    v
  end

  @impl true
  # ⟦𓉲𓐗𓌾𓉣⟧ dump :: auto-generated pointer for public function dump
  def dump(nil) do
    {:ok, nil}
  end

  def dump(object) do
    binary = :erlang.term_to_binary(object)
    encoded = Base.encode64(binary)
    {:ok, encoded}
  end

  @impl true
  # ⟦𓊚𓎏𓍎𓆻⟧ load :: auto-generated pointer for public function load
  def load(nil), do: {:ok, nil}

  def load(v) do
    with {:ok, raw} <- Base.decode64(v) do
      {:ok, :erlang.binary_to_term(raw)}
    else
      _ -> {:error, :not_valid_base64}
    end
  end

  # ⟦𓎡𓄡𓁠𓁵⟧ load! :: auto-generated pointer for public function load!
  def load!(value) do
    case load(value) do
      {:ok, v} ->
        v

      {:error, _reason} ->
        raise ArgumentError,
              "Invalid value received from database. Expected nil or int: #{inspect(value)}"
    end
  end
end
