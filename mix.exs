defmodule Mix.Tasks.Compile.ElixirLGE do
  def run(_args) do
    {result, _errcode} = System.cmd("gcc",
      [
        "-I", "E:/erlang/erl-23.3/erts-11.2/include",
        "--std=c++11",
        "-m64",
        "-shared",
        "-o", "dll/test.dll",
        "native_lib/test.c"
      ], stderr_to_stdout: true)
    IO.puts(result)
  end
end

defmodule ElixirLGE.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_lge,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:ElixirLGE] ++ Mix.compilers
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirLGE.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
