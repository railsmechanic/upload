defmodule Upload.Config do
  @moduledoc """
  Helper module for Configuration-
  """

  @doc """
  Get a configuration variable with fallback to a given default value.
  """
  @spec get(Atom.t(), Atom.t(), any) :: any
  def get(module, key, fallback) do
    Application.get_env(:upload, module, [])
    |> Keyword.get(key, fallback)
    |> normalize_config()
  end

  @doc """
  Get a configuration variable, or raise an error.
  """
  @spec fetch!(Atom.t(), Atom.t()) :: any | no_return
  def fetch!(module, key) do
    Application.get_env(:upload, module, [])
    |> Keyword.fetch!(key)
    |> normalize_config()
  end

  ## - Helper functions
  defp normalize_config({:system, varname}), do: System.get_env(varname)
  defp normalize_config(value), do: value
end
