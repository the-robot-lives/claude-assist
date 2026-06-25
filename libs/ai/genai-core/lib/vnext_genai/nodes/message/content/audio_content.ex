defmodule GenAI.Message.Content.AudioContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct source: nil, # {:file, path} | :response | {:uri, path},
            type: nil, # {:file, path} |  binary | {:uri, path}, | {:upload, id}
            transcript: "AUDIO TRANSCRIPT NOT AVAILABLE",
            length: nil,
            resource: nil, # {:base64, encoded} | {:upload, id} |  {:uri, path}
            options: nil,
            meta: nil,
            vsn: @vsn

  @doc """
  Get image type based on file extension.
  """
  def file_type({:uri, resource}) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".wave") -> :wav
      String.ends_with?(resource, ".mp3") -> :mp3
      true -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type({:file, resource}) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".wave") -> :wav
      String.ends_with?(resource, ".mp3") -> :mp3
      true -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type(resource) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".wave") -> :wav
      String.ends_with?(resource, ".mp3") -> :mp3
      true -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type(_), do: nil

  @doc """
  Get image resolution.
  """
  def audio_length(_), do: :auto

  @doc """
  Base64 encode image content.
  """
  def base64(resource, options \\ nil)

  def base64(path, _) when is_bitstring(path) do
    binary = File.read!(path)
    {:ok, Base.encode64(binary)}
  end
  def base64({:file, path}, _) do
    binary = File.read!(path)
    {:ok, Base.encode64(binary)}
  end
  def base64({:base64, encoded}, _) do
    {:ok, encoded}
  end



  @doc """
  Prepare new image message content item.
  """
  def new(resource, options \\ nil)

  def new(options, _) when is_list(options) do
    keys =
      __MODULE__.__info__(:struct)
      |> Enum.map(& &1.field)
      |> MapSet.new()

    options =     options
                  |> Enum.to_list()

    option_field = options
                   |> Enum.reject(&MapSet.member?(keys, elem(&1, 0)))
                   |> Enum.into(%{})

    merge = [options: option_field]
    merge = is_nil(options[:type]) && [{:type, file_type(options[:source]) }| merge] || merge
    merge = is_nil(options[:length]) && [{:length, audio_length(options[:resource])} | merge] || merge

    options
    |> Keyword.merge(merge)
    |> Enum.filter(&MapSet.member?(keys, elem(&1, 0)))
    |> __struct__()
  end


  def new({:uri, resource}, options) do
    (options || [])
    |> Enum.to_list()
    |> put_in([:source], {:uri, resource})
    |> put_in([:resource], {:uri, resource})
    |> new()
  end

  def new({:file, resource}, options)  do
    File.exists?(resource) || throw("Resource not found: #{resource}")
    {:ok, encoded} = base64(resource, options)
    (options || [])
    |> Enum.to_list()
    |> put_in([:source], {:file, resource})
    |> put_in([:resource], {:base64, encoded})
    |> new()
  end

  def new(resource = {:base64, _encoded}, options)  do
    {:ok, encoded} = base64(resource, options)
    (options || [])
    |> Enum.to_list()
    |> update_in([:source], & &1 || :base64)
    |> put_in([:resource], {:base64, encoded})
    |> new()
  end

  def new({:upload, id}, options)  do
    (options || [])
    |> Enum.to_list()
    |> update_in([:source], & &1 || {:upload, id})
    |> put_in([:resource], {:upload, id})
    |> new()
  end

  def new(resource = "http" <> _path, options) when is_bitstring(resource) do
    (options || [])
    |> Enum.to_list()
    |> put_in([:source], {:uri, resource})
    |> put_in([:resource], {:uri, resource})
    |> new()
  end

  def new(resource, options) when is_bitstring(resource) do
    File.exists?(resource) || throw("Resource not found: #{resource}")
    {:ok, encoded} = base64(resource, options)

    (options || [])
    |> put_in([:source], {:file, resource})
    |> put_in([:resource], {:base64, encoded})
    |> new()
  end



  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
