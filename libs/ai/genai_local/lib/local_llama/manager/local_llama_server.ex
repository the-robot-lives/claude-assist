defmodule GenAI.Provider.LocalLLamaServer do
  use GenServer
  #alias Phoenix.PubSub
  @vsn 1.0

  defstruct [
    local_models: %{},
    vsn: @vsn
  ]

  # ⟦𓆙𓆞𓋾𓅍⟧ start_link :: auto-generated pointer for public function start_link
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  # ⟦𓍴𓀐𓊮𓎆⟧ init :: auto-generated pointer for public function init
  def init(state) do
    #    set_generation_key()
    #    load_runtime_settings()
    {:ok, state}
  end

  @impl true
  # ⟦𓐩𓍜𓋲𓎺⟧ handle_call :: auto-generated pointer for public function handle_call
  def handle_call(call, from, state)
  def handle_call({:get_models, settings}, from, state) do
    do_get_models(state, from, settings)
  end

  def handle_call({:get_model, handle, settings}, from, state) do
    do_get_model(state, from, handle, settings)
  end

  @doc """

  """
  # ⟦𓋅𓂎𓃱𓁊⟧ get_models :: auto-generated pointer for public function get_models
  def get_models(settings \\ [])
  def get_models(settings) do
    GenServer.call(__MODULE__, {:get_models, settings})
  end

  defp do_get_models(state, from, settings)
  defp do_get_models(state, _, _settings) do
    models = Enum.map(state.local_models, fn {_,model} -> model end)
    {:reply, {:ok, models}, state}
  end

  @doc """

  """
  # ⟦𓉥𓉂𓉟𓀤⟧ get_model :: auto-generated pointer for public function get_model
  def get_model(handle, settings \\ [])
  def get_model(handle, settings) do
    GenServer.call(__MODULE__, {:get_model, handle, settings})
  end

  defp do_get_model(state, from, handle, settings)
  defp do_get_model(state, _, handle, _settings) do
    response = with {:ok, identifier} <- GenAI.ModelProtocol.handle(handle) do
      if live_model = state.local_models[identifier] do
        {:ok, live_model}
      else
        # Load Model
        {:error, :not_found}
      end
    end
    {:reply, response, state}
  end



  #
  #  defp load_runtime_settings() do
  #    # async gencast
  #    :persistent_term.put(runtime_setting_key(:models), {:ok, []})
  #  end
  #
  #  defp set_generation_key() do
  #    :persistent_term.put({__MODULE__, :generation_key}, self())
  #    :pending
  #  end
  #  defp get_generation_key() do
  #    with :undefined <- :persistent_term.get({__MODULE__, :generation_key}, :undefined) do
  #      {:error, :not_initialized}
  #    else
  #      x -> {:ok, x}
  #    end
  #  end
  #
  #  defp runtime_setting_key(setting) do
  #    {__MODULE__, :runtime_setting, setting}
  #  end
  #
  #  def subscribe(setting, options) do
  #    # use syn to subscribe to setting on local node.
  #    :ok
  #  end
  #
  #  defp setting_update(setting, message) do
  #    # todo use syn to broadcast message.
  #    :ok
  #  end
  #
  #  def request_setting(setting, options) do
  #    # semaphore logic
  #    if options[:blocking] do
  #      {:pending, :subscribe_and_request}
  #    else
  #      {:pending, :request}
  #    end
  #  end
  #
  #  def runtime_setting(setting, options) do
  #    case  :persistent_term.get(runtime_setting_key(name), :__genai_undefined__) do
  #      :__genai_undefined__ -> request_setting(setting, options)
  #      x = {:error, _} -> x
  #      x = {:loading, _reference} ->
  #        if options[:blocking] do
  #          {:pending, :subscribe_and_wait}
  #        else
  #          :loading
  #        end
  #      x = {:ok, _} -> x
  #      x -> throw "Invalid Internal State"
  #    end
  #  end


end
