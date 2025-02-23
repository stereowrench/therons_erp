defmodule TheronsErp.Scheduler do
  @moduledoc """
  The Scheduler module is responsible for scheduling POs, MOs,
  and movements based on route rules.

  # How it works

  The scheduler takes all of the BoMs and ensures there are no cycles. Then the
  scheduler creates processes for each location.

  """
end
