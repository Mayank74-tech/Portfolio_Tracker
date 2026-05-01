# Mock Bank API

Local mock bank API project for testing finance integrations.

## Run

```bash
dart pub get
dart run bin/server.dart
```

Server runs on `http://localhost:8080`.

## Endpoints

- `GET /health`
- `GET /banks`
- `POST /connect`
- `GET /accounts/<accountId>/transactions`
- `GET /accounts/<accountId>/balance`

