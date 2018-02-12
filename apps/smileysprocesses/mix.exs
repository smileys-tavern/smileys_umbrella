defmodule SmileysProcesses.Mixfile do
  use Mix.Project

  def project do
    [
      app: :smileysprocesses,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SmileysProcesses.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.9", override: true},
      {:quantum, ">= 2.2.1"},
      {:feeder_ex, "~> 1.1"},
      {:cloudex, "~> 0.1.10"},
      {:syn, "1.6.1"},
      {:bamboo, "~> 0.8.0"},
      {:simplestatex, "~> 0.1.3"},

      # Smileys
      #{:smileysdata, path: "../../../smileys_data"}
      {:smileysdata, git: "https://github.com/smileys-tavern/smileys_data.git", tag: "0.1.2"}
    ]
  end
end
