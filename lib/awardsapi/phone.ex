defmodule Awardsapi.Phone do
  @moduledoc """
  Utility module to deal with phone number logic
  """

  @doc """
  Normalize a phone number (using ExPhoneNumber)
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(phone_number) do
    {:ok, number} = ExPhoneNumber.parse(phone_number, "")
    ExPhoneNumber.format(number, :e164)
  end
end
