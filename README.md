# Awardsapi

## Setup

To start your Phoenix server:

  * Clone the repo
  * Run `mix deps.get && mix ecto.setup && mix phx.server` to start the application
  * You can also run `mix test` to run the tests

## Configuration

A few things are pre-configured in the application: 
  * The set of valid currency codes that the application accepts (defaults to `["JPY"]`)
  * The currency to which the order price has to be converted in order for the points to be calculated
  * The default percentage (expressed in [basis points](https://en.wikipedia.org/wiki/Basis_point)) of the price that is converted into points


## The DB schema

For the sake of simplicity SQLite is used. The tables are defined in the migration, and are as folows:

### orders

| <!-- -->    | <!-- -->    |
|-------------|-------------|
| id        | autoincremeted id |
| remote_id | id as provided in the request, string, unique |
| price     | integer stores whole "cents" (or whatever is the lowest unit in said currency) |
| currency  | the character currency code, stored in uppercase |

### customers

| <!-- -->    | <!-- -->    |
|-------------|-------------|
| id | autoincremented id |
| points | number of reward points that this customer has |
| basis_points | The reward percentage for this particular customer, by default it's null and we use the application default |

### customer_emails

| <!-- -->    | <!-- -->    |
|-------------|-------------|
| id | autoincremeted id |
| customer_id | To which customer does this email belong to (should be a reference to customers, not enforced at db level) |
| email | The email address - unique |

### customer_phones

| <!-- -->    | <!-- -->    |
|-------------|-------------|
| id | autoincremeted id |
| customer_id | To which customer does this email belong to (should be a reference to customers, not enforced at db level) |
| phone | The phone number - unique, should be normalized before storing (and querying) |

## Endpoints

The api exposes several endpoints:

### POST `/orders/new`

Accepts the following JSON
```json
{
  "order" : {
    "id" : "1",       // arbitrary unique id string
    "paid": 123,      // number. Amount paid in a given currency
    "currency": "XXX" // A three letter currency code (case-insensitive)
  },
  "customer": {
    "email": "email@somewhere.com", // Email address of the customer, used to identify them, can be null if phone is provided
    "phone": "+12345667890",        // Phone number of the customer, used to identify then, cab be null if email is provided
  }
}
```

and does the following things:

1) validates the data, 
2) in case of a previously unseen customer, creates the customer record
3) in case of a previously unseen transaction, inserts the transaction and awards the customer with points based on the paid amount

In case of a repeated request (same transaction id), the endpoint returns a 200, and internaly does nothing.

Should the email and phone belong to different customers, these customers are merged into a single customer, as we assume that simply the customer has more than one email address or a phone number.

### GET `/customer/balance/by_email/email@example.com`

Retrieves the customer balance for a customer that has the provided email address.
Should no such customer be found returns a 404

### GET `/customer/balance/by_phone/+123445769`

Retrieves the customer balance for a customer that has the provided phone number.
Should no such customer be found returns a 404

### POST `/customer/balance/by_email/email@example.com`

Accepts the following JSON
```json
{
  "action": "action_name", // valid action names are "add" and "remove"
  "amount": 123,           // amount of points to be added to or removed from the ballance
}
```

Retrieves the customer balance for a customer that has the provided email address.
Should no such customer be found returns a 404

If the `"action"` and `"amount"` are valid, then either adds or removes the amount of points provided in the `amount`.
In case of `"remove"` we also check that the `"amount"` is not greater than the current balance, otherwise we return a 400

### POST `/customer/balance/by_phone/+123456789`

Accepts the following JSON
```json
{
  "action": "action_name", // valid action names are "add" and "remove"
  "amount": 123,           // amount of points to be added to or removed from the ballance
}
```

Retrieves the customer balance for a customer that has the provided phone number.
Should no such customer be found returns a 404

If the `"action"` and `"amount"` are valid, then either adds or removes the amount of points provided in the `amount`.
In case of `"remove"` we also check that the `"amount"` is not greater than the current balance, otherwise we return a 400

### POST `/customer/award_percentage/by_email/email@example.com`

Accepts the following JSON:
```json
{
  "new_basis_points": 123 // The new awards percentage expressed in basis points for this customer
}
```
Retrieves the customer balance for a customer that has the provided email address.
Should no such customer be found returns a 404 otherwise (given valid data) sets the provided value as the new awards basis points for future orders for this customer


### POST `/customer/award_percentage/by_phone/+1234567889`

Accepts the following JSON:
```json
{
  "new_basis_points": 123 // The new awards percentage expressed in basis points for this customer
}
```
Retrieves the customer balance for a customer that has the provided phone number.
Should no such customer be found returns a 404 otherwise (given valid data) sets the provided value as the new awards basis points for future orders for this customer


