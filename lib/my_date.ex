defmodule MyDate do
  if Mix.env() == :test do
    def today() do
      if :ets.whereis(:mydate) == :undefined do
        ~D[2022-03-01]
      else
        :ets.lookup(:mydate, :today)
        |> Keyword.get(:today)
      end
    end

    def now!() do
      t = today()
      DateTime.new!(t, ~T[13:26:08.003])
    end
  else
    def today() do
      Date.utc_today()
    end

    def now() do
      DateTime.utc_now()
    end
  end
end
