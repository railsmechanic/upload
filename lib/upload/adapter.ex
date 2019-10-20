defmodule Upload.Adapter do
  @moduledoc """
  A behaviour that specifies how an adapter should work.
  """

  ## - Macro definition
  defmacro __using__(_) do
    quote do
      @behaviour Upload.Adapter
    end
  end

  ## - Custom adapter error
  defmodule Error do
    defexception message: "Unable to process request"
  end

  ## - Behaviour definitions
  @callback base_url :: {:ok, String.t()} | {:error, String.t()}
  @callback base_url! :: String.t()
  @callback get_url(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  @callback get_url!(String.t()) :: String.t()
  @callback get_signed_url(String.t(), Keyword.t()) :: {:ok, String.t()} | {:error, String.t()}
  @callback get_signed_url!(String.t(), Keyword.t()) :: String.t()
  @callback transfer(Upload.t()) :: {:ok, Upload.t()} | {:error, String.t()}
  @callback transfer!(Upload.t()) :: Upload.t()
end
