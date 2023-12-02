defmodule AwardsapiWeb.BasisPointsTest do
  use AwardsapiWeb.ConnCase, async: false

  test "create order then update basis points and then do a second order and check that other users are not affected",
       %{conn: conn} do
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

    assert %Plug.Conn{status: 200, resp_body: json_resp} =
             AwardsapiWeb.CustomersController.post_award_percentage(conn, %{
               "email" => "aaa@example.com",
               "new_basis_points" => 200
             })

    decoded_json = Jason.decode!(json_resp)
    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)
    assert %{"balance" => ^expected_points, "basis_points" => 200} = decoded_json

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "2",
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

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate) + 200
    assert %{"balance" => ^expected_points} = decoded_json

    assert %Plug.Conn{status: 200} =
             AwardsapiWeb.OrdersController.create(conn, %{
               "order" => %{
                 "id" => "3",
                 "paid" => 10_000,
                 "currency" => "jpy"
               },
               "customer" => %{
                 "email" => "bbb@example.com",
                 "phone" => nil
               }
             })

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"email" => "bbb@example.com"})

    decoded_json = Jason.decode!(json_resp)

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate)
    assert %{"balance" => ^expected_points} = decoded_json
  end

  test "set basis points on nonexisting user", %{conn: conn} do
    assert %Plug.Conn{resp_body: json_resp, status: 404} =
             AwardsapiWeb.CustomersController.post_award_percentage(conn, %{
               "email" => "aaa@example.com",
               "new_basis_points" => 200
             })

    decoded_json = Jason.decode!(json_resp)

    assert %{"error" => "not found"} = decoded_json
  end

  test "four orders that will merge customers, but one of them has custom basis points", %{
    conn: conn
  } do
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
             AwardsapiWeb.CustomersController.post_award_percentage(conn, %{
               "phone" => "+316 2 6808 481",
               "new_basis_points" => 200
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

    assert %Plug.Conn{resp_body: json_resp, status: 200} =
             AwardsapiWeb.CustomersController.get_balance(conn, %{"email" => "bbb@example.com"})

    decoded_json = Jason.decode!(json_resp)

    expected_points = Application.fetch_env!(:awardsapi, :basis_rate) * 2 + 200 * 2
    assert %{"balance" => ^expected_points} = decoded_json
  end
end
