# BookingApi sample

A deliberately small, fictional API that makes the walkthroughs in `examples/` concrete. Members create bookings and read only their own.

## Run the tests

```bash
cd samples/csharp
dotnet test
```

## Run the API locally

```bash
cd samples/csharp
dotnet run --project BookingApi
```

```bash
# Create a booking (standard tier)
curl -s -X POST http://localhost:5108/bookings \
  -H "X-Api-Key: local-demo-key-standard" -H "Content-Type: application/json" \
  -d '{"nights": 2}'

# Read it back with its id; the premium member's key gets 404 for the same id
curl -s http://localhost:5108/bookings/<id> -H "X-Api-Key: local-demo-key-standard"
```

The two demo keys in `appsettings.Development.json` are fictional and work only in the Development environment. A real service never commits keys; it uses the organisation's identity provider.

## Endpoints

| Method | Path | Result |
|---|---|---|
| `POST` | `/bookings` | 201 with the booking, 400 if nights is outside 1–30, 401 without a valid key |
| `GET` | `/bookings/{id}` | 200 for your own booking, 404 otherwise, 401 without a valid key |
