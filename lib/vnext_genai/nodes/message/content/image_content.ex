defmodule GenAI.Message.Content.ImageContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct source: nil,
            type: nil,
            resolution: nil,
            resource: nil,
            options: nil,
            meta: nil,
            vsn: @vsn

  @doc """
  Get image type based on file extension.
  """
  def file_type({:uri, resource}) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".png") -> :png
      String.ends_with?(resource, ".jpg") -> :jpeg
      String.ends_with?(resource, ".jpeg") -> :jpeg
      String.ends_with?(resource, ".gif") -> :gif
      String.ends_with?(resource, ".bmp") -> :bmp
      String.ends_with?(resource, ".tiff") -> :tiff
      String.ends_with?(resource, ".webp") -> :webp
      :else -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type({:file, resource}) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".png") -> :png
      String.ends_with?(resource, ".jpg") -> :jpeg
      String.ends_with?(resource, ".jpeg") -> :jpeg
      String.ends_with?(resource, ".gif") -> :gif
      String.ends_with?(resource, ".bmp") -> :bmp
      String.ends_with?(resource, ".tiff") -> :tiff
      String.ends_with?(resource, ".webp") -> :webp
      :else -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type(resource) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".png") -> :png
      String.ends_with?(resource, ".jpg") -> :jpeg
      String.ends_with?(resource, ".jpeg") -> :jpeg
      String.ends_with?(resource, ".gif") -> :gif
      String.ends_with?(resource, ".bmp") -> :bmp
      String.ends_with?(resource, ".tiff") -> :tiff
      String.ends_with?(resource, ".webp") -> :webp
      true -> throw("Unsupported image type: #{resource}")
    end
  end
  def file_type(_), do: nil

  @doc """
  Get image resolution.
  """
  def resolution(_), do: :auto

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
  def base64(%__MODULE__{resource: resource}, options) do
    base64(resource, options)
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
    merge = is_nil(options[:type]) && [{:type, file_type(options[:source])} | merge] || merge
    merge = is_nil(options[:resolution]) && [{:resolution, resolution(options[:resource])} | merge] || merge

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
    |> Enum.to_list()
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
