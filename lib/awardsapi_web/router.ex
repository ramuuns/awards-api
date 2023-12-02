defmodule AwardsapiWeb.Router do
  use AwardsapiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AwardsapiWeb do
    pipe_through :api

    post "/orders/new", OrdersController, :create

    get "/customer/balance/by_email/:email", CustomersController, :get_balance
    get "/customer/balance/by_phone/:phone", CustomersController, :get_balance

    post "/customer/balance/by_email/:email", CustomersController, :post_balance
    post "/customer/balance/by_phone/:phone", CustomersController, :post_balance

    post "/customer/award_percentage/by_email/:email", CustomersController, :post_award_percentage
    post "/customer/award_percentage/by_phone/:phone", CustomersController, :post_award_percentage
  end
end
