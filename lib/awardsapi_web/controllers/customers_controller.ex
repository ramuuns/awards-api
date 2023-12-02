defmodule AwardsapiWeb.CustomersController do
  alias Awardsapi.Customers
  use AwardsapiWeb, :controller

  def get_balance(conn, params) do
    maybe_customer =
      case params do
        %{"email" => email} -> Customers.check_for_customer_by_email(email)
        %{"phone" => phone} -> Customers.check_for_customer_by_phone(phone)
      end

    case maybe_customer do
      {:ok, customer} ->
        conn
        |> put_status(200)
        |> json(%{
          balance: customer.points
        })

      _ ->
        conn
        |> put_status(404)
        |> json(%{
          error: "not found"
        })
    end
  end

  def post_balance(conn, params) do
    maybe_customer =
      case params do
        %{"email" => email} -> Customers.check_for_customer_by_email(email)
        %{"phone" => phone} -> Customers.check_for_customer_by_phone(phone)
      end

    case maybe_customer do
      {:ok, customer} ->
        maybe_perform_balance_action(conn, customer, params)

      _ ->
        conn
        |> put_status(404)
        |> json(%{
          error: "not found"
        })
    end
  end

  def post_award_percentage(conn, params) do
    maybe_customer =
      case params do
        %{"email" => email} -> Customers.check_for_customer_by_email(email)
        %{"phone" => phone} -> Customers.check_for_customer_by_phone(phone)
      end

    case maybe_customer do
      {:ok, customer} ->
        maybe_change_award_percentage(conn, customer, params)

      _ ->
        conn
        |> put_status(404)
        |> json(%{
          error: "not found"
        })
    end
  end

  defp maybe_perform_balance_action(conn, customer, params) do
    maybe_ok_params = validate_action_params(params)

    case maybe_ok_params do
      {:ok, action, amount} ->
        maybe_perform_action(conn, customer, action, amount)

      _ ->
        conn
        |> put_status(400)
        |> json(%{
          error: "invalid action"
        })
    end
  end

  defp maybe_perform_action(conn, %{points: current_points}, :remove, amount)
       when amount > current_points do
    conn |> put_status(400) |> json(%{error: "not enough points"})
  end

  defp maybe_perform_action(conn, customer, :remove, amount) do
    customer = Customers.add_points(customer, -amount)
    conn |> put_status(200) |> json(%{balance: customer.points})
  end

  defp maybe_perform_action(conn, customer, :add, amount) do
    customer = Customers.add_points(customer, amount)
    conn |> put_status(200) |> json(%{balance: customer.points})
  end

  defp validate_action_params(%{"action" => action, "amount" => amount})
       when is_binary(action) and (action == "add" or action == "remove") and is_number(amount),
       do: {:ok, action |> String.to_atom(), amount}

  defp validate_action_params(_), do: {:error}

  defp maybe_change_award_percentage(conn, customer, %{"new_basis_points" => bps})
       when is_number(bps) and bps >= 0 do
    customer = Customers.set_basis_points(customer, bps)

    conn
    |> put_status(200)
    |> json(%{balance: customer.points, basis_points: customer.basis_points})
  end

  defp maybe_change_award_percentage(conn, _, _) do
    conn |> put_status(400) |> json(%{error: "invalid parameters"})
  end
end
