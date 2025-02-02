defmodule TheronsErpWeb.KeywordHighlighter do
  use TheronsErpWeb, :live_component

  def highlight(string, matches, value) do
    assigns = %{
      string: string,
      matches: matches
    }

    case matches do
      nil ->
        ~H"<%= @string %>"

      _ ->
        hs =
          0..(String.length(string) - 1)
          |> Enum.map(fn idx ->
            case idx in matches do
              true ->
                assigns = %{string: string, idx: idx}
                ~H"<b><%= String.at(@string, @idx) %></b>"

              false ->
                assigns = %{string: string, idx: idx}
                ~H"<%= String.at(@string, @idx) %>"
            end
          end)

        assigns = %{hs: hs}

        if value < 0 do
          ~H"""
          <span class="text-purple-400" phx-no-format><%= for h <- @hs do %><%= h %><% end %></span>
          """
        else
          ~H"""
          <span phx-no-format><%= for h <- @hs do %><%= h %><% end %></span>
          """
        end
    end
  end
end
