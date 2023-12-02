defmodule Awardsapi.Models.CustomerPhone do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "customer_phones" do
    field :customer_id, :integer
    field :phone, :string
  end

  @spec create(integer(), String.t()) :: Ecto.Changeset.t()
  def create(customer_id, phone) do
    change(%__MODULE__{}, %{
      customer_id: customer_id,
      phone: Awardsapi.Phone.normalize(phone)
    })
  end
end
