defmodule Awardsapi.Repo do
  use Ecto.Repo,
    otp_app: :awardsapi,
    adapter: Ecto.Adapters.SQLite3
end
