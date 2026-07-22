defmodule GenAI.Helpers do
  @moduledoc """
  A collection of helper functions for VNextGenAI.
  """

  @doc """
  label block response
  ## Examples

  ### OK Response
      iex> require GenAI.Helpers
      iex> GenAI.Helpers.with_label(:foo) do
      iex>    {:ok, :bar}
      iex> end
      {:foo, :bar}

  ### Error Response
      iex> require GenAI.Helpers
      iex> GenAI.Helpers.with_label(:foo) do
      iex>    {:error, :bar}
      iex> end
      {:error, {:foo, :bar}}

  ### Non Tuple Response
      iex> require GenAI.Helpers
      iex> GenAI.Helpers.with_label(:foo) do
      iex>    :bop
      iex> end
      {:foo, :bop}

  """
  # ⟦𓋩𓊵𓉀𓅘⟧ with_label :: label block response
  defmacro with_label(label, do: block) do
    quote do
      unquote(block)
      |> case do
        {:ok, response} -> {unquote(label), response}
        {:error, error} -> {:error, {unquote(label), error}}
        response -> {unquote(label), response}
      end
    end
  end

  @doc """
  label response
  ## Examples

  ### OK Response
      iex> GenAI.Helpers.apply_label({:ok, :bar}, :foo)
      {:foo, :bar}

  ### Error Response
      iex> GenAI.Helpers.apply_label({:error, :bar}, :foo)
      {:error, {:foo, :bar}}

  ### Non Tuple Response
      iex> GenAI.Helpers.apply_label(:bop, :foo)
      {:foo, :bop}

  """
  # ⟦𓈫𓊛𓀴𓎰⟧ apply_label :: label response
  def apply_label(response, label) do
    case response do
      {:ok, response} -> {label, response}
      {:error, error} -> {:error, {label, error}}
      response -> {label, response}
    end
  end

  @doc """
  Handle error tuple response.

  ## Examples

      iex> {:ok, :return_me} |> GenAI.Helpers.on_error(:label, :unexpected)
      {:ok, :return_me}

      iex> {:ok, nil} |> GenAI.Helpers.on_error(:label, :unexpected)
      {:ok, nil}

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:return_value, :bar)
      {:ok, :bar}

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:return_error, :bar)
      {:error, :bar}

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:return, :bar)
      :bar

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:call, fn -> :biz end)
      :biz

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:call, fn x -> {:biz, x} end)
      {:biz, {:error, :foo}}

      iex> {:error, :foo} |> GenAI.Helpers.on_error(:label, :wrap)
      {:error, {:wrap, :foo}}
  """
  @spec on_error({:ok, any} | {:error, any}, atom, any) :: any
  # ⟦𓈯𓃅𓎋𓊗⟧ on_error :: Handle error tuple response.
  def on_error(response, action, value)
  def on_error(response = {:ok, _}, _, _), do: response
  def on_error({:error, _}, :return_value, value), do: {:ok, value}
  def on_error({:error, _}, :return_error, value), do: {:error, value}
  def on_error({:error, _}, :return, value), do: value
  def on_error({:error, _}, :call, value) when is_function(value, 0), do: value.()

  def on_error({:error, _} = response, :call, value) when is_function(value, 1),
    do: value.(response)

  def on_error({:error, error}, :label, label), do: {:error, {label, error}}

  @doc """
    Handle {:ok, nil} tuple response.
    ## Examples
      iex> {:ok, 5} |> GenAI.Helpers.on_nil(:label, :unexpected)
      {:ok, 5}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return_value, :bar)
      {:ok, :bar}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return_error, :bar)
      {:error, :bar}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return, :bar)
      :bar

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:call, fn -> :biz end)
      :biz

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:label, :wrap)
      {:error, {:wrap, :is_nil}}

      iex> {:error, :foo} |> GenAI.Helpers.on_nil(:label, :wrap)
      {:error, :foo}

  """
  @spec on_nil({:ok, any} | {:error, any}, atom, any) :: any
  # ⟦𓉾𓅇𓅨𓌪⟧ on_nil :: Handle {:ok, nil} tuple response.
  def on_nil(response, action, value)
  def on_nil({:ok, nil}, :return_value, value), do: {:ok, value}
  def on_nil({:ok, nil}, :return_error, value), do: {:error, value}
  def on_nil({:ok, nil}, :return, value), do: value
  def on_nil({:ok, nil}, :call, value) when is_function(value, 0), do: value.()
  def on_nil({:ok, nil}, :call, value) when is_function(value, 1), do: value.({:ok, nil})
  def on_nil({:ok, nil}, :label, label), do: {:error, {label, :is_nil}}
  def on_nil(response, _, _), do: response
end
