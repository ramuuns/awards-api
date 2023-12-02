defmodule Awardsapi.Customers do
  @moduledoc """
  Defines the business logic for dealing with customers
  """
  alias Awardsapi.Phone
  alias Awardsapi.Models.Customer
  alias Awardsapi.Models.CustomerEmail
  alias Awardsapi.Models.CustomerPhone
  import Ecto.Query

  @doc """
  given an email/phone (in a map) will find a customer by said email/phone or create
  a new customer if it doesn't exist. Returns the found/created customer record
  """
  @spec maybe_add_customer(map()) :: {:ok, Awardsapi.Models.Customer.t()}
  def maybe_add_customer(%{"email" => email, "phone" => nil} = customer) do
    case check_for_customer_by_email(email) do
      {:ok, customer} ->
        {:ok, customer}

      _ ->
        create_customer(customer)
    end
  end

  def maybe_add_customer(%{"email" => nil, "phone" => phone} = customer) do
    case check_for_customer_by_phone(phone) do
      {:ok, customer} -> {:ok, customer}
      _ -> create_customer(customer)
    end
  end

  def maybe_add_customer(%{"email" => email, "phone" => phone} = customer) do
    {cust_e, cust_p} = {
      check_for_customer_by_email(email),
      check_for_customer_by_phone(phone)
    }

    customer =
      case {cust_e, cust_p} do
        {{:ok, cust}, {:ok, cust}} ->
          cust

        {{:ok, cust_a}, {:ok, cust_b}} ->
          merge_customers(cust_a, cust_b)

        {{:ok, cust_a}, _} ->
          add_phone(cust_a, phone)
          cust_a

        {_, {:ok, cust_b}} ->
          add_email(cust_b, email)
          cust_b

        _ ->
          create_customer(customer)
      end

    {:ok, customer}
  end

  @doc """
  Given email/phone, create a new customer record and return it
  """
  @spec create_customer(map()) :: {:ok, Awardsapi.Models.Customer.t()}
  def create_customer(%{"email" => email, "phone" => phone}) do
    {:ok, customer} = Customer.create() |> Awardsapi.Repo.insert()

    if email != nil do
      {:ok, _} = add_email(customer, email)
    end

    if phone != nil do
      {:ok, _} = add_phone(customer, phone)
    end

    {:ok, customer}
  end

  @doc """
  Add a phone number to a customer, returns the added phone number record
  """
  @spec add_phone(Awardsapi.Models.Customer.t(), String.t()) ::
          {:ok, Awardsapi.Models.CustomerPhone.t()} | {:error, Ecto.Changeset.t()}
  def add_phone(customer, phone) do
    CustomerPhone.create(customer.id, phone) |> Awardsapi.Repo.insert()
  end

  @doc """
  Add an email address to a customer, returns the added email address record
  """
  @spec add_email(Awardsapi.Models.Customer.t(), String.t()) ::
          {:ok, Awardsapi.Models.CustomerEmail.t()} | {:error, Ecto.Changeset.t()}
  def add_email(customer, email) do
    CustomerEmail.create(customer.id, email) |> Awardsapi.Repo.insert()
  end

  @doc """
  Merge two customer records.

  When merging all phone numbers/emails associated with the second customer are moved to the first customer,
  the award points are added and saved in the first customer, if the second customer has custom basis_points
  that are higher than the first customers basis_points, then those are also moved to the first customer.
  Afterwards the second customer is deleted
  """
  @spec merge_customers(Awardsapi.Models.Customer.t(), Awardsapi.Models.Customer.t()) ::
          Awardsapi.Models.Customer.t()
  def merge_customers(cust_a, cust_b) do
    {:ok, cust} =
      Awardsapi.Repo.transaction(fn repo ->
        query = from e in CustomerEmail, where: e.customer_id == ^cust_b.id
        repo.update_all(query, set: [customer_id: cust_a.id])
        query = from e in CustomerPhone, where: e.customer_id == ^cust_b.id
        repo.update_all(query, set: [customer_id: cust_a.id])

        {:ok, cust} = Customer.add_points(cust_a, cust_b.points) |> repo.update()

        # merge basis points, the logic being if any has custom bps use theirs
        #  if both have custom bps, keep the highest
        cust =
          cond do
            cust_b.basis_points != nil and cust_a.basis_points == nil ->
              {:ok, cust} = Customer.set_basis_points(cust, cust_b.basis_points) |> repo.update()
              cust

            cust_b.basis_points != nil and cust_a.basis_points != nil and
                cust_b.basis_points > cust_a.basis_points ->
              {:ok, cust} = Customer.set_basis_points(cust, cust_b.basis_points) |> repo.update()
              cust

            true ->
              cust
          end

        cust_b |> repo.delete()
        cust
      end)

    cust
  end

  @doc """
  Tries to find a customer record given an email, returns the customer if found
  """
  @spec check_for_customer_by_email(String.t()) :: {:ok, Awardsapi.Models.Customer.t()} | {:err}
  def check_for_customer_by_email(email) do
    query = from e in CustomerEmail, where: e.email == ^email

    case Awardsapi.Repo.one(query) do
      %{customer_id: id} -> {:ok, from(c in Customer, where: c.id == ^id) |> Awardsapi.Repo.one()}
      _ -> {:err}
    end
  end

  @doc """
  Tries to find a customer record given a phone number, returns the customer if found
  """
  @spec check_for_customer_by_phone(String.t()) :: {:ok, Awardsapi.Models.Customer.t()} | {:err}
  def check_for_customer_by_phone(phone) do
    normalized_phone = Phone.normalize(phone)
    query = from p in CustomerPhone, where: p.phone == ^normalized_phone

    case Awardsapi.Repo.one(query) do
      %{customer_id: id} -> {:ok, from(c in Customer, where: c.id == ^id) |> Awardsapi.Repo.one()}
      _ -> {:err}
    end
  end

  @doc """
  Add reward points to customer, returns the modified customer
  """
  @spec add_points(Awardsapi.Models.Customer.t(), integer()) :: Awardsapi.Models.Customer.t()
  def add_points(customer, points) do
    {:ok, cust} = Customer.add_points(customer, points) |> Awardsapi.Repo.update()
    cust
  end

  @doc """
  Set the awards basis points for a customer, returns the modified customer
  """
  @spec set_basis_points(Awardsapi.Models.Customer.t(), integer()) ::
          Awardsapi.Models.Customer.t()
  def set_basis_points(customer, points) do
    {:ok, cust} = Customer.set_basis_points(customer, points) |> Awardsapi.Repo.update()
    cust
  end
end
