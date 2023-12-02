defmodule Awardsapi.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table("orders") do
      add :remote_id, :string, null: false
      add :price, :integer, null: false
      add :currency, :string, size: 3, null: false
    end

    unique_index("orders", :remote_id)

    create table("customers") do
      add :points, :integer, null: false
      add :basis_points, :integer, null: true
    end

    create table("customer_emails") do
      add :customer_id, :integer, null: false
      add :email, :string, null: false
    end

    index("customer_emails", :customer_id)
    unique_index("customer_emails", :email)

    create table("customer_phones") do
      add :customer_id, :integer, null: false
      add :phone, :string, null: false
    end

    index("customer_phones", :customer_id)
    unique_index("customer_phones", :phone)
  end
end
