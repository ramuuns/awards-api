defmodule AwardsapiWeb.OrdersController do
  use AwardsapiWeb, :controller
  alias Awardsapi.Customers
  alias Awardsapi.Orders

  def create(conn, params) do
    {status, _} =
      case validate_params(params) do
        :ok ->
          %{"order" => order, "customer" => input_customer} = params
          {:ok, customer} = Customers.maybe_add_customer(input_customer)
          Orders.process_order(order, customer)

        :err ->
          {:err, ""}
      end

    conn |> put_status(http_status_for(status)) |> json(json_resp_for(status))
  end

  defp http_status_for(:ok), do: 200
  defp http_status_for(:err), do: 400

  defp json_resp_for(:ok), do: %{status: "ok"}
  defp json_resp_for(:err), do: %{status: "err"}

  defp validate_params(%{"customer" => customer, "order" => order}) do
    if validate_customer(customer) and validate_order(order) do
      :ok
    else
      :err
    end
  end

  defp validate_params(_), do: :err

  defp validate_customer(%{"email" => nil, "phone" => nil}), do: false
  defp validate_customer(%{"email" => email, "phone" => nil}), do: looks_like_an_email(email)
  defp validate_customer(%{"email" => nil, "phone" => phone}), do: looks_like_a_phone(phone)

  defp validate_customer(%{"email" => email, "phone" => phone}),
    do: looks_like_an_email(email) and looks_like_a_phone(phone)

  defp validate_customer(_), do: false

  defp validate_order(%{"id" => id, "paid" => paid, "currency" => currency})
       when id != nil and is_number(paid) and is_binary(currency) do
    paid > 0 and is_acceptable_currency(currency)
  end

  defp validate_order(_), do: false

  # validating email is hard, so we can just do the simple dumb thing, and call it a day
  #  alternatively one could use something like https://github.com/maennchen/email_checker
  # that said the only true way to know that something is a legit email address is to send an
  #  email to that address with a confirmation link and have the user click it.
  #  For the purposes of this api we'll assume that this part is done upstream, and that
  #  we only have to guard against malformed data (e.g. the upstream application putting wrong data in the
  # email field), rather than this being something that's directly tied to user input
  defp looks_like_an_email(email) when is_binary(email) do
    email |> String.contains?("@")
  end

  defp looks_like_an_email(_), do: false

  # use libphonenumber to check if the string could possibly be a phone number
  defp looks_like_a_phone(phone) when is_binary(phone) do
    ExPhoneNumber.is_possible_number?(phone, nil)
  end

  defp looks_like_a_phone(_), do: false

  defp is_acceptable_currency(currency) do
    currency = String.upcase(currency)
    valid_currencies = Application.fetch_env!(:awardsapi, :valid_currencies)
    MapSet.member?(valid_currencies, currency)
  end
end
