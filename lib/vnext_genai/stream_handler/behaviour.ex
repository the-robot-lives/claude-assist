defmodule GenAI.StreamHandler do
  
  def begin_stream(handler, session, context, options) when is_atom(handler) do
    handler.begin_stream(handler, session, context, options)
  end
  def begin_stream(%{__struct__: h} = handler, session, context, options) do
    h.begin_stream(handler, session, context, options)
  end

end

defmodule GenAI.StreamHandler.Behaviour do
  @callback begin_stream(handler :: term, session :: term, context :: term, options :: term) :: {:ok, {{state :: term, handler :: term}, session :: term}} | {:error, reason :: term}
  @callback handle_event(event :: term, state :: term) :: {:cont, state :: term} | {:halt, state :: term}
end

defmodule GenAI.StreamHandler.Default do
  @behaviour GenAI.StreamHandler.Behaviour
  
  defmodule Accumulator do
    defstruct [
      headers: nil,
      status: nil,
      chunks: [],
      buffer: "",
      completed: false,
      error: nil,
      trailers: nil
    ]
  end
  
  @doc """
  Initialize streaming with default handler that returns handle_event callback
  """
  def begin_stream(_handler, session, _context, _options) do
    # Initialize state for collecting stream chunks
    initial_state = %Accumulator{}
    
    # Return initial state and callback function reference
    {:ok, {{initial_state, &__MODULE__.handle_event/2}, session}}
  end
  
  @doc """
  Handle streaming events from Finch.stream_while
  Processes status, headers, data chunks, and trailers
  """
  def handle_event(event, state) do
    case event do
      {:status, status} ->
        # Store HTTP status
        {:cont, Map.put(state, :status, status)}
        
      {:headers, headers} ->
        # Store headers
        {:cont, Map.put(state, :headers, headers)}
        
      {:data, chunk} ->
        # Accumulate data chunks
        updated_state = state
          |> Map.update(:chunks, [chunk], &(&1 ++ [chunk]))
          |> Map.update(:buffer, chunk, &(&1 <> chunk))
        {:cont, updated_state}
        
      {:trailers, trailers} ->
        # Store trailers if any
        {:cont, Map.put(state, :trailers, trailers)}
        
      _ ->
        # Continue with current state for unknown events
        {:cont, state}
    end
  end
end