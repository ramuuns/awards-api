defmodule AwardsapiWeb.BalanceTest do
  use AwardsapiWeb.ConnCase, async: false

  test "create order and check balance", %{conn: conn} do
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

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"email" => "aaa@example.com"})

    decoded_json = Jason.decode!(json_resp)

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)
    assert %{"balance" => ^expected_points} = decoded_json
  end

  test "get balance on nonexisting user", %{conn: conn} do
    assert %Plug.Conn{resp_body: json_resp, status: 404} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"email" => "aaa@example.com"})

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "not found"} = decoded_json
  end

  test "update balance on nonexisting user", %{conn: conn} do
    assert %Plug.Conn{resp_body: json_resp, status: 404} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => 100,
               "action" => "add"
             })

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "not found"} = decoded_json
  end

  test "invalid action", %{conn: conn} do
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

    assert %Plug.Conn{resp_body: json_resp, status: 400} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => 100,
               "action" => "adddddddddddddd"
             })

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "invalid action"} = decoded_json
  end

  test "not a valid number in amount", %{conn: conn} do
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

    assert %Plug.Conn{resp_body: json_resp, status: 400} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => "add100",
               "action" => "add"
             })

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "invalid action"} = decoded_json
  end

  test "too high number when removing", %{conn: conn} do
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

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)

    assert %Plug.Conn{resp_body: json_resp, status: 400} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => expected_points * 10,
               "action" => "remove"
             })

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "not enough points"} = decoded_json
  end

  test "add points then remove points", %{conn: conn} do
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

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => 1000,
               "action" => "add"
             })

    decoded_json = Jason.decode!(json_resp)

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate) + 1000
    assert %{"balance" => ^expected_points} = decoded_json

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.post_balance(conn, %{
               "email" => "aaa@example.com",
               "amount" => 1000,
               "action" => "remove"
             })

    decoded_json = Jason.decode!(json_resp)
    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)
    assert %{"balance" => ^expected_points} = decoded_json
  end
end
