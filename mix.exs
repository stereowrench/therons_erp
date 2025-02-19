defmodule TheronsErp.MixProject do
  use Mix.Project

  def project do
    [
      app: :therons_erp,
      version: "0.1.0",
      elixir: "~> 1.18.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TheronsErp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ex_money_sql, "~> 1.0"},
      {:picosat_elixir, "~> 0.2"},
      {:sourceror, "~> 1.7", only: [:dev, :test]},
      {:oban, "~> 2.0"},
      {:ash_paper_trail, "~> 0.5"},
      {:ash_archival, "~> 1.0"},
      {:ash_double_entry, "~> 1.0"},
      {:ash_state_machine, "~> 0.2"},
      {:ash_oban, "~> 0.3"},
      {:ash_money, "~> 0.1"},
      {:ash_authentication_phoenix, "~> 2.0"},
      {:ash_authentication, "~> 4.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash_phoenix, "~> 2.0"},
      {:ash, "~> 3.0"},
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:live_select, "~> 1.0"},
      {:seqfuzz, "~> 0.2.0"},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:petal_components, "~> 2.8"},
      {:credo, "~> 1.7"},
      {:faker, "~> 0.18.0", only: :test},
      {:phoenix_test, "~> 0.5.2", only: :test, runtime: false},
      {:ash_admin, "~> 0.13.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind therons_erp", "esbuild therons_erp"],
      "assets.deploy": [
        "tailwind therons_erp --minify",
        "esbuild therons_erp --minify",
        "phx.digest"
      ]
    ]
  end
end
