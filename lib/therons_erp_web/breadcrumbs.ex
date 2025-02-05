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

  def has_breadcrumb?([]) do
    false
  end

  def has_breadcrumb?(_breadcrumbs) do
    true
  end

  defp to_json_map({route, action}) do
    %{route: route, action: action}
  end

  defp to_json_map({route, action, args}) do
    %{route: route, action: action, args: args}
  end

  defp to_json_map({route, action, param, args}) do
    %{route: route, action: action, param: param, args: args}
  end

  defp from_json_map(%{"route" => route, "action" => action, "args" => args, "param" => param}) do
    {route, action, param, args}
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

  def navigate_back(socket, from, args \\ nil) do
    breadcrumbs = socket.assigns.breadcrumbs
    {path, _breadcrumbs} = _navigate_back(breadcrumbs, from, args)

    socket
    |> assign(:breadcrumbs, encode_breadcrumbs(breadcrumbs))
    |> Phoenix.LiveView.redirect(to: path)
  end

  defp _navigate_back(_breadcrumbs, _from, args \\ nil)

  defp _navigate_back([], from, args) do
    which =
      case from do
        {"product_category", "new", _product_category_id} ->
          ~p"/product_categories"

        {"products", "edit", product_id} ->
          ~p"/products/#{product_id}"
      end

    {which, []}
  end

  defp _navigate_back([breadcrumb | breadcrumbs], _from, from_args) do
    which =
      case breadcrumb do
        {"products", "new", args} ->
          if from_args do
            ~p"/products/new?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: args, from_args: from_args]}"
          else
            ~p"/products/new?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: args]}"
          end

        {"products", "edit", pid, args} ->
          if from_args do
            ~p"/products/#{pid}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: args, from_args: from_args]}"
          else
            ~p"/products/#{pid}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: args]}"
          end
      end

    {which, breadcrumbs}
  end

  def navigate_to(socket, part, from) do
    socket
    |> Phoenix.LiveView.redirect(to: navigate_to_url(socket.assigns.breadcrumbs, part, from))
  end

  def navigate_to_url(breadcrumbs, {"product_categories"}, from) do
    ~p"/product_categories?#{[breadcrumbs: append_and_encode(breadcrumbs, from)]}"
  end

  def navigate_to_url(breadcrumbs, {"product_category", "new", product_id}, from) do
    ~p"/product_categories/new?#{[breadcrumbs: append_and_encode(breadcrumbs, from), product_id: product_id]}"
  end

  def navigate_to_url(breadcrumbs, {"product_category", id}, from) do
    ~p"/product_categories/#{id}?#{[breadcrumbs: append_and_encode(breadcrumbs, from)]}"
  end

  defp append_and_encode(breadcrumbs, breadcrumb) do
    [breadcrumb | breadcrumbs]
    |> encode_breadcrumbs()
  end
end
