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
  else
    def today() do
      Date.utc_today()
    end
  end
end
