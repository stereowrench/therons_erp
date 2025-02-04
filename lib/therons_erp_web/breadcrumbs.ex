defmodule TheronsErpWeb.Breadcrumbs do
  import Phoenix.Component
  use TheronsErpWeb, :verified_routes

  def on_mount(:default, params, _session, socket) do
    socket = assign(socket, :breadcrumbs, decode_breadcrumbs(params["breadcrumbs"]))
    socket = assign(socket, :wat, 3)
    {:cont, socket}
  end

  def decode_breadcrumbs(nil) do
    []
  end

  def decode_breadcrumbs(breadcrumbs) do
    # base 64 code then JSON decode
    breadcrumbs
    |> Base.decode64!()
    |> Jason.decode!()
    |> Enum.map(&from_json_map/1)
  end

  defp to_json_map({route, action}) do
    %{route: route, action: action}
  end

  defp to_json_map({route, action, args}) do
    %{route: route, action: action, args: args}
  end

  defp from_json_map(%{"route" => route, "action" => action, "args" => args}) do
    {route, action, args}
  end

  defp from_json_map(%{"route" => route, "action" => action}) do
    {route, action}
  end

  def encode_breadcrumbs(breadcrumbs) do
    breadcrumbs
    |> Enum.map(&to_json_map/1)
    |> Jason.encode!()
    |> Base.encode64()
  end

  # def render_breadcrumbs()

  def get_previous_path(breadcrumbs, from) do
    {path, _} = _navigate_back(breadcrumbs, from)
    path
  end

  def navigate_back(socket, from) do
    breadcrumbs = socket.assigns.breadcrumbs
    path = _navigate_back(breadcrumbs, from)

    socket
    |> Phoenix.LiveView.redirect(to: path)
  end

  defp _navigate_back([], from) do
    which =
      case from do
        {"product_category", "new", product_id} ->
          ~p"/product_categories"
      end

    {which, []}
  end

  defp _navigate_back([breadcrumb | breadcrumbs], _from) do
    which =
      case breadcrumb do
        {"product", "new", args} ->
          ~p"/products/new?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: args]}"
      end

    {which, breadcrumbs}
  end

  def navigate_to(socket, {"product_categories"}, from) do
    socket
    |> Phoenix.LiveView.redirect(
      to: ~p"/product_categories?#{[breadcrumbs: append_and_encode(socket, from)]}"
    )
  end

  def navigate_to(socket, {"product_category", "new", product_id}, from) do
    socket
    |> Phoenix.LiveView.redirect(
      to:
        ~p"/product_categories/new?#{[breadcrumbs: append_and_encode(socket, from), product_id: product_id]}"
    )
  end

  defp append_and_encode(socket, breadcrumb) do
    breadcrumbs = socket.assigns.breadcrumbs

    [breadcrumb | breadcrumbs]
    |> IO.inspect()
    |> encode_breadcrumbs()
  end
end
