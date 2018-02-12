defmodule SmileysProcessesTest do
  use ExUnit.Case
  doctest SmileysProcesses

  test "greets the world" do
    assert SmileysProcesses.hello() == :world
  end
end
