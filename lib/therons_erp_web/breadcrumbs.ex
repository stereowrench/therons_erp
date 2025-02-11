defmodule TheronsErpWeb.Breadcrumbs do
  import Phoenix.Component
  use TheronsErpWeb, :html

  def on_mount(:default, params, _session, socket) do
    socket = assign(socket, :breadcrumbs, decode_breadcrumbs(params["breadcrumbs"]))
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

        {"product_category", product_category_id, _name} ->
          ~p"/product_categories/#{product_category_id}"

        {"products", "edit", product_id} ->
          ~p"/products/#{product_id}"

        {"people", entity_id} ->
          ~p"/people/#{entity_id}"
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

        {"products", pid, _identifier} ->
          if from_args do
            ~p"/products/#{pid}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), from_args: from_args]}"
          else
            ~p"/products/#{pid}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs)]}"
          end

        {"product_category", id, _name} ->
          if from_args do
            ~p"/product_categories/#{id}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), from_args: from_args]}"
          else
            ~p"/product_categories/#{id}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs)]}"
          end

        {"sales_orders", id, params, _identifier} ->
          if from_args do
            ~p"/sales_orders/#{id}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), from_args: from_args, args: params]}"
          else
            ~p"/sales_orders/#{id}?#{[breadcrumbs: encode_breadcrumbs(breadcrumbs), args: params]}"
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

  def navigate_to_url(breadcrumbs, {"product_category", "new_cat", category_id}, from) do
    ~p"/product_categories/new?#{[breadcrumbs: append_and_encode(breadcrumbs, from), category_id: category_id]}"
  end

  def navigate_to_url(breadcrumbs, {"product_category", id, _full_name}, from) do
    ~p"/product_categories/#{id}?#{[breadcrumbs: append_and_encode(breadcrumbs, from)]}"
  end

  def navigate_to_url(breadcrumbs, {"products", "new", line_id}, from) do
    ~p"/products/new?#{[breadcrumbs: append_and_encode(breadcrumbs, from), line_id: line_id]}"
  end

  def navigate_to_url(breadcrumbs, {"products", id, _name}, from) do
    ~p"/products/#{id}?#{[breadcrumbs: append_and_encode(breadcrumbs, from)]}"
  end

  defp append_and_encode(breadcrumbs, breadcrumb) do
    [breadcrumb | breadcrumbs]
    |> encode_breadcrumbs()
  end

  defp name_for_crumb({"products", "edit", pid}) do
    "Edit #{pid}"
  end

  defp name_for_crumb({"products", "edit", pid, _}) do
    "Edit #{pid}"
  end

  defp name_for_crumb({"products", _pid, identifier}) do
    "#{identifier}"
  end

  defp name_for_crumb({"product_category", _cid, name}) do
    "#{name}"
  end

  defp name_for_crumb({"sales_orders", _sale_id, _params, serial_no}) do
    "S#{serial_no}"
  end

  def stream_crumbs(list) when is_list(list) do
    _stream_crumbs(list)
  end

  # Handle empty list case. Important!
  defp _stream_crumbs([]), do: []

  defp _stream_crumbs(current_list = [_ | rest]) do
    Stream.concat([
      [current_list],
      # Recursive call
      stream_crumbs(rest)
    ])
  end

  def render_breadcrumbs(assigns) do
    case assigns.breadcrumbs do
      [first] ->
        assigns = assign(assigns, :first, first)

        ~H"""
        <span class="breadcrumbs">
          <.link href={_navigate_back([@first], nil, nil) |> elem(0)}>
            {name_for_crumb(@first)}
          </.link>
        </span>
        """

      [first, second] ->
        assigns =
          assign(assigns, :first, first)
          |> assign(:second, second)

        ~H"""
        <span class="breadcrumbs">
          <.link href={_navigate_back([@second], nil, nil) |> elem(0)}>
            {name_for_crumb(@second)}
          </.link>
          /
          <.link href={_navigate_back([@first, @second], nil, nil) |> elem(0)}>
            {name_for_crumb(@first)}
          </.link>
        </span>
        """

      [first, second | rest] ->
        assigns =
          assign(assigns, :first, first)
          |> assign(:second, second)
          |> assign(:rest, rest)

        ~H"""
        <span class="breadcrumbs">
          <PC.dropdown js_lib="live_view_js" placement="right">
            <%= for crumb = [f | _] <- stream_crumbs(@rest) do %>
              <PC.dropdown_menu_item link_type="a" to={_navigate_back(crumb, nil, nil) |> elem(0)}>
                {name_for_crumb(f)}
              </PC.dropdown_menu_item>
            <% end %>
          </PC.dropdown>
          /
          <.link href={_navigate_back([@second | @rest], nil, nil) |> elem(0)}>
            {name_for_crumb(@second)}
          </.link>
          /
          <.link href={_navigate_back([@first, @second | @rest], nil, nil) |> elem(0)}>
            {name_for_crumb(@first)}
          </.link>
        </span>
        """

      [] ->
        ~H"""
        """
    end
  end
end
