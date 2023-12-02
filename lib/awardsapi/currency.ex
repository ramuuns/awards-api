defmodule Awardsapi.Currency do
  @moduledoc """
  provides the business logic to deal with currencies
  """

  # a map that sets the multiplier to convert a value in currency to the "cents" or (which is how they are then stored in the database)
  @currency_config %{
    "JPY" => 1
  }

  @doc """
  given a price and a currency return the amount that will be stored in the database (as an integer)
  """
  @spec price_for_db(number(), String.t()) :: integer()
  def price_for_db(price, currency) do
    multiplier = @currency_config[currency]
    round(price * multiplier)
  end

  @doc """
  convert the provided amount to the base currency for awards calculation
  the base currency is the one defined in the application configuration
  """
  @spec ensure_amount_in_base_currency(number(), String.t()) :: number()
  def ensure_amount_in_base_currency(amount, curency) do
    currency_for_points = Application.fetch_env!(:awardsapi, :currency_for_points)

    if currency_for_points != curency do
      convert_currency_to_base(amount, curency, currency_for_points)
    else
      amount
    end
  end

  @doc """
  Convert currency from source currency to target currency

  NOT IMPLEMENTED will raise an exception if called
  """
  @spec convert_currency_to_base(number(), String.t(), String.t()) :: number()
  def convert_currency_to_base(_amount, _from, _to) do
    raise "currency conversion is not implemented"
  end
end
