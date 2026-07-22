defmodule Mix.Tasks.Codefresh.Gen.Openapi do
  @moduledoc """
  Generate a deterministic OpenAPI route snapshot for Codefresh.

  The snapshot is intentionally conservative at M0: it freezes paths, methods,
  operation ids, auth shape, and default JSON responses. Later milestones can
  enrich operation schemas without renegotiating the route contract.
  """
  use Mix.Task

  @shortdoc "Generates docs/openapi.json from the Phoenix router"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile")

    spec =
      CodefreshWeb.Router
      |> Phoenix.Router.routes()
      |> Enum.reject(&internal_route?/1)
      |> Enum.reduce(base_spec(), &put_route/2)

    payload = Jason.encode!(spec, pretty: true) <> "\n"
    File.mkdir_p!("docs")
    File.write!("docs/openapi.json", payload)

    if "--snapshot" in args do
      File.mkdir_p!("../../docs")
      File.write!("../../docs/openapi.json", payload)
    end

    Mix.shell().info("Generated docs/openapi.json")
  end

  defp base_spec do
    %{
      "openapi" => "3.1.0",
      "info" => %{
        "title" => "CodeFresh API",
        "version" => "0.1.0",
        "description" => "Route-level contract snapshot generated from CodefreshWeb.Router."
      },
      "servers" => [
        %{"url" => "https://codefre.sh"},
        %{"url" => "http://localhost:4000"}
      ],
      "components" => %{
        "securitySchemes" => %{
          "bearerAuth" => %{
            "type" => "http",
            "scheme" => "bearer",
            "bearerFormat" => "JWT"
          },
          "apiToken" => %{
            "type" => "http",
            "scheme" => "bearer",
            "description" => "Organization-scoped API token for CLI, SDK, and OTLP ingest."
          }
        }
      },
      "paths" => %{}
    }
  end

  defp put_route(route, spec) do
    path = openapi_path(route.path)
    method = route.verb |> to_string() |> String.downcase()
    operation = route_operation(route)

    update_in(spec, ["paths"], fn paths ->
      path_item = Map.get(paths, path, %{})
      Map.put(paths, path, Map.put(path_item, method, operation))
    end)
  end

  defp route_operation(route) do
    tags = route_tags(route)

    %{
      "operationId" => operation_id(route),
      "tags" => tags,
      "summary" => summary(route),
      "parameters" => path_parameters(route.path),
      "security" => security(route),
      "responses" => %{
        "200" => json_response("Successful response"),
        "401" => json_response("Authentication required"),
        "403" => json_response("Permission denied"),
        "422" => json_response("Validation failed")
      }
    }
  end

  defp internal_route?(route) do
    String.starts_with?(route.path, "/dev")
  end

  defp openapi_path(path) do
    Regex.replace(~r/:([A-Za-z_][A-Za-z0-9_]*)/, path, "{\\1}")
  end

  defp path_parameters(path) do
    ~r/:([A-Za-z_][A-Za-z0-9_]*)/
    |> Regex.scan(path, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn name ->
      %{
        "name" => name,
        "in" => "path",
        "required" => true,
        "schema" => %{"type" => "string"}
      }
    end)
  end

  defp operation_id(route) do
    controller =
      route.plug
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> String.replace("_controller", "")

    action = route.plug_opts |> to_string() |> String.replace_suffix("!", "")
    "#{controller}_#{action}"
  end

  defp route_tags(route) do
    tag =
      route.plug
      |> Module.split()
      |> List.last()
      |> String.replace_suffix("Controller", "")

    [tag]
  end

  defp summary(route) do
    "#{route.verb} #{openapi_path(route.path)}"
  end

  defp security(route) do
    cond do
      String.starts_with?(route.path, "/otel/v1") -> [%{"apiToken" => []}]
      String.starts_with?(route.path, "/api/v1/auth/") -> []
      route.path == "/health" -> []
      true -> [%{"bearerAuth" => []}]
    end
  end

  defp json_response(description) do
    %{
      "description" => description,
      "content" => %{
        "application/json" => %{
          "schema" => %{"type" => "object"}
        }
      }
    }
  end
end
