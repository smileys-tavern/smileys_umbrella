defmodule Smileysapi.Mixfile do
  use Mix.Project

  def project do
    [app: :smileysapi,
     version: "0.0.2",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.7",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Smileysapi.Application, []},
     extra_applications: [:logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.2"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.10"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:httpoison, "~> 0.11.0", override: true},
     {:poison, "~> 3.0", override: true},
     {:hackney, "~> 1.9", override: true},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:jose, "~> 1.8"},
     {:guardian, "~> 0.14.4"},
     {:hashids, "~> 2.0"},
     {:decimal, "~> 1.4", override: true},
     {:cachex, "~> 2.0"},
     {:cloudex, "~> 0.1.10"},
     {:kerosene, "~> 0.5.0"},
     {:scout_apm, "~> 0.3.2"},
     {:absinthe, "~> 1.3.1"},
     {:absinthe_plug, "~> 1.1"},
     {:syn, "1.6.1"},
     {:quantum, ">= 2.2.7"},

     # Smileys
     {:smileysdata, git: "https://github.com/smileys-tavern/smileys_data.git", tag: "0.1.2"},
     #{:smileysdata, path: "../../../smileys_data"},
     {:smileyssearch, git: "https://github.com/smileys-tavern/smileys_search.git", tag: "0.0.5"}
     #{:smileyssearch, path: "../../../smileys_search"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
