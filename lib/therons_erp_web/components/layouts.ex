defmodule TheronsErpWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use TheronsErpWeb, :controller` and
  `use TheronsErpWeb, :live_view`.
  """
  use TheronsErpWeb, :html

  embed_templates "layouts/*"

  attr :active, :atom, required: true
  attr :name, :atom, required: true
  attr :path, :string, required: true
  attr :text, :string, required: true
  attr :icon, :string, default: nil
  attr :todo, :string, default: nil

  def nav_link(%{} = assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={(if @active == @name, do: "bg-eagle-100 text-mojo-600", else: "text-eagle-700 hover:text-mojo-600 hover:bg-eagle-100") <> " group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"}
    >
      <%= if @icon do %>
        <.icon name={@icon} />
      <% end %>
      {@text}
      <%= if @todo && @todo > 0 do %>
        <PC.badge color="warning" label={"Todo #{@todo}"} />
      <% end %>
    </.link>
    """
  end

  def status_badge(assigns) do
    case assigns.state do
      :draft ->
        ~H"""
        <PC.badge color="warning">Draft</PC.badge>
        """

      :ready ->
        ~H"""
        <PC.badge color="success">Ready</PC.badge>
        """

      :sent ->
        ~H"""
        <PC.badge color="success">Sent</PC.badge>
        """

      :canceled ->
        ~H"""
        <PC.badge color="danger">Canceled</PC.badge>
        """

      _ ->
        ~H"""
        <PC.badge color="info">{assigns.state}</PC.badge>
        """
    end
  end
end
