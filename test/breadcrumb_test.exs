defmodule TheronsErpWeb.BreadcrumbTest do
  use TheronsErpWeb.ConnCase

  test "stream_crumbs" do
    out =
      [1, 2, 3]
      |> TheronsErpWeb.Breadcrumbs.stream_crumbs()
      |> Enum.to_list()

    assert ^out = [[1, 2, 3], [2, 3], [3]]
  end
end
