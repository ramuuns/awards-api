defmodule Awardsapi.Models.CustomerEmail do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "customer_emails" do
    field :customer_id, :integer
    field :email, :string
  end

  @spec create(integer(), String.t()) :: Ecto.Changeset.t()
  def create(customer_id, email) do
    change(%__MODULE__{}, %{
      customer_id: customer_id,
      email: email
    })
  end
end
