defmodule Awardsapi.Models.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "customers" do
    field :points, :integer
    field :basis_points, :integer
  end

  @spec create() :: Ecto.Changeset.t()
  def create() do
    change(%__MODULE__{}, %{points: 0})
  end

  @spec add_points(Awardsapi.Models.Customer.t(), number()) :: Ecto.Changeset.t()
  def add_points(%__MODULE__{} = current, points) do
    change(current, %{points: current.points + points})
  end

  @spec set_basis_points(Awardsapi.Models.Customer.t(), any()) :: Ecto.Changeset.t()
  def set_basis_points(%__MODULE__{} = current, bps) do
    change(current, %{basis_points: bps})
  end
end
