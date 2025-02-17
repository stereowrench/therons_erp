defmodule TheronsErpWeb.Nav do
  use TheronsErpWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {so, _}
        when so in [TheronsErpWeb.SalesOrderLive.Index, TheronsErpWeb.SalesOrderLive.Show] ->
          :sales_orders

        {po, _} when po in [TheronsErpWeb.ProductLive.Index, TheronsErpWeb.ProductLive.Show] ->
          :products

        {pp, _} when pp in [TheronsErpWeb.EntityLive.Index, TheronsErpWeb.EntityLive.Show] ->
          :people

        {pc, _}
        when pc in [
               TheronsErpWeb.ProductCategoryLive.Index,
               TheronsErpWeb.ProductCategoryLive.Show
             ] ->
          :product_categories

        {_, _} ->
          nil
      end

    {:cont, assign(socket, :active_tab, active_tab)}
  end
end
