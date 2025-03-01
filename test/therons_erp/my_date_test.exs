defmodule TheronsErp.MyDateTest do
  use ExUnit.Case

  test "default date" do
    assert MyDate.today() == ~D[2022-03-01]
  end

  test "setting date" do
    :ets.new(:mydate, [:set, :public, :named_table])
    :ets.insert(:mydate, {:today, ~D[2022-04-01]})

    assert MyDate.today() == ~D[2022-04-01]
  end
end
