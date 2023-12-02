defmodule AwardsapiWeb.OrdersTest do
  alias Awardsapi.Models.CustomerPhone
  alias Awardsapi.Models.Customer
  alias Awardsapi.Models.CustomerEmail
  alias Awardsapi.Models.Order
  use AwardsapiWeb.ConnCase, async: false
  import Ecto.Query

  test "order is created", %{conn: conn} do
    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => nil
               }
             })

    email = from(e in CustomerEmail, where: e.email == "aaa@example.com") |> Awardsapi.Repo.one()

    assert %CustomerEmail{email: "aaa@example.com"} = email

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)

    assert %Customer{points: ^expected_points} =
             Awardsapi.Repo.one(from(c in Customer, where: c.id == ^email.customer_id))

    assert %Order{id: 1, remote_id: "1", currency: "JPY"} =
             Awardsapi.Repo.one(from(o in Order, where: o.remote_id == "1"))
  end

  test "repeat order is ignored", %{conn: conn} do
    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => nil
               }
             })

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => nil
               }
             })

    email = from(e in CustomerEmail, where: e.email == "aaa@example.com") |> Awardsapi.Repo.one()

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)

    assert %Customer{points: ^expected_points} =
             Awardsapi.Repo.one(from(c in Customer, where: c.id == ^email.customer_id))
  end

  test "invalid customer email", %{conn: conn} do
    resp =
      AwardsapiWeb.OrdersController.create(conn, %{
        "order" => %{
          "id" => "1",
          "paid" => 10_000,
          "currency" => "jpy"
        },
        "customer" => %{
          "email" => "not-an-email",
          "phone" => nil
        }
      })

    assert %Plug.Conn{status: 400} = resp

    email = from(e in CustomerEmail, where: e.email == "not-an-email") |> Awardsapi.Repo.one()

    assert email == nil
  end

  test "invalid customer phone", %{conn: conn} do
    resp =
      AwardsapiWeb.OrdersController.create(conn, %{
        "order" => %{
          "id" => "1",
          "paid" => 10_000,
          "currency" => "jpy"
        },
        "customer" => %{
          "email" => nil,
          "phone" => "+123456"
        }
      })

    assert %Plug.Conn{status: 400} = resp

    phone = from(p in CustomerPhone, where: p.phone == "+1234456") |> Awardsapi.Repo.one()

    assert phone == nil

    assert %Plug.Conn{status: 404} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"phone" => "+1234456"})
  end

  test "check phone normalization", %{conn: conn} do
    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => nil,
                 "phone" => "+31 6 26 80 8481"
               }
             })

    phone = from(p in CustomerPhone, where: p.phone == "+31626808481") |> Awardsapi.Repo.one()

    assert %CustomerPhone{phone: "+31626808481"} = phone
  end

  test "four orders that will merge customers", %{conn: conn} do
    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => nil
               }
             })

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "2",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => nil,
                 "phone" => "+31626808481"
               }
             })

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "3",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => "+316268084 81"
               }
             })

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "4",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "bbb@example.com",
                 "phone" => "+31626 808481"
               }
             })

    customer_records = Awardsapi.Repo.all(from(Customer))

    assert Enum.count(customer_records) == 1

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate) * 4
    assert [%{points: ^expected_points}] = customer_records

    email_records = Awardsapi.Repo.all(from(CustomerEmail))
    phone_records = Awardsapi.Repo.all(from(CustomerPhone))

    assert Enum.count(email_records) == 2
    assert Enum.count(phone_records) == 1

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"email" => "aaa@example.com"})

    decoded_json = Jason.decode!(json_resp)

    assert %{"balance" => ^expected_points} = decoded_json
  end

  test "unsupported currency", %{conn: conn} do
    assert %Plug.Conn{status: 400} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "1",
                 "paid" => 10_000,
                 "currency" => "usd"
               },
               "customer" => %{
                 "email" => "aaa@example.com",
                 "phone" => nil
               }
             })
  end
end
