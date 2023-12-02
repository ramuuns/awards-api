defmodule Awardsapi.Models.Order do
  use Ecto.Schema
  import Ecto.Changeset
  alias Awardsapi.Currency

  @type t :: %__MODULE__{}

  schema "orders" do
    field :remote_id, :string
    field :price, :integer
    field :currency, :string
  end

  @spec create(map()) :: Ecto.Changeset.t()
  def create(%{"id" => id, "paid" => paid, "currency" => currency}) do
    currency = String.upcase(currency)

    change(%__MODULE__{}, %{
      remote_id: id,
      price: Currency.price_for_db(paid, currency),
      currency: currency
    })
  end
end
