defmodule Awardsapi.Orders do
  @moduledoc """
  Business logic of processing the orders
  """
  import Ecto.Query
  alias Awardsapi.Models.Order
  alias Awardsapi.Models.Customer
  alias Awardsapi.Currency

  @doc """
  Process an order for a customer.
  Checks if this order is already processed, in which case it simply returns the customer struct,
  otherwise we store and process the order and calculate the award points for this order, which are then
  stored in the customer record, which is updated and returned
  """
  @spec process_order(map(), Awardsapi.Models.Customer.t()) ::
          {:ok, Awardsapi.Models.Customer.t()} | {:error, any()} | Ecto.Multi.failure()
  def process_order(order, %Customer{} = customer) do
    query = from o in Order, where: o.remote_id == ^order["id"]

    case Awardsapi.Repo.one(query) do
      %{id: _} ->
        {:ok, customer}

      _ ->
        points = points_from_order(order, customer)

        Awardsapi.Repo.transaction(fn repo ->
          Order.create(order) |> repo.insert()
          {:ok, cust} = Customer.add_points(customer, points) |> repo.update()
          cust
        end)
    end
  end

  @doc """
  Given an order and a customer, calculate the amount of award points.
  """
  @spec points_from_order(map(), Awardsapi.Models.Customer.t()) :: integer()
  def points_from_order(%{"paid" => paid, "currency" => currency}, %{basis_points: basis_points}) do
    currency = String.upcase(currency)
    base_amount = Currency.ensure_amount_in_base_currency(paid, currency)
    basis_points = basis_points || Application.fetch_env!(:awardsapi, :basis_rate)
    percentage = basis_points / 10_000
    round(base_amount * percentage)
  end
end
