defmodule Smileyscaretaker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :smileyscaretaker,
      version: "0.0.4",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5.1",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end


  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Smileyscaretaker.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:poison, "~> 3.0", override: true},
      {:httpoison, "~> 0.11.0", override: true},
      {:hackney, "~> 1.9", override: true},

      {:quantum, "~> 2.0.0"},
      {:feeder_ex, "~> 1.1"},
      {:cloudex, "~> 0.1.10"},
      {:syn, "1.6.1"},
      {:bamboo, "~> 0.8.0"},

      # Smileys
      #{:smileysdata, path: "../../../smileys_data"}
      {:smileysdata, git: "https://github.com/smileys-tavern/smileys_data.git", tag: "0.0.16"}
    ]
  end
end
