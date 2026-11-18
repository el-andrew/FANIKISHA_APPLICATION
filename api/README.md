# Fanikisha API

Backend for **Fanikisha** ("make it succeed" in Swahili), a savings app for
owners of small and medium businesses in Tanzania. Owners set savings goals
(new stock, equipment, rent) and record deposits; the API splits every deposit
across their goals according to each goal's priority and how far it is from
its deadline.

## Features

- **Accounts:** registration and login, short-lived access tokens with rotating
  refresh tokens (a reused refresh token signs the device out), password change
  that signs out every device.
- **Goals:** target amount, priority (1–5), deadline, progress, and the daily
  amount needed to finish on time.
- **Deposits:** split automatically across active goals. A goal never receives
  more than it needs; the excess is kept as general savings. Retries with the
  same `Idempotency-Key` are recorded once.
- **Summary:** totals for a dashboard.

## How a deposit is split

Each active goal gets a share proportional to

```
priority × (amount still needed ÷ days left)
```

so urgent, important goals fill first. The split is in whole shillings and
always adds up to the deposit. See [`src/savings/allocation.ts`](src/savings/allocation.ts)
and its tests, which include 2,000 randomly generated cases.

## Tech stack

NestJS 12 (TypeScript, ESM) · PostgreSQL · Prisma 7 · Zod · `@nestjs/authentication`
(scrypt password hashing, JWT) · Vitest · oxlint

## Running locally

Requirements: Node.js 22.12 or newer, and Docker (or any PostgreSQL 14+).

```bash
cp .env.example .env            # then set JWT_SECRET (instructions inside)
docker compose up -d db         # PostgreSQL on localhost:5432
npm install                     # also generates the Prisma client
npm run db:migrate              # create the tables
npm run start:dev               # http://localhost:3000
```

Check it's running: `curl http://localhost:3000/health`.

## Tests

```bash
npm test                        # unit tests
cp .env.test.example .env.test  # once
npm run test:e2e                # API tests against a real database
```

The end-to-end suite uses the `fanikisha_test` database and deletes its
contents, so it refuses to run against a database whose name lacks "test".
Create it once with `docker compose exec db createdb -U fanikisha fanikisha_test`.

## API

All routes except `/health` and `/v1/auth/*` need `Authorization: Bearer <accessToken>`.
Amounts are whole shillings; dates are `YYYY-MM-DD`.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | API and database status |
| POST | `/v1/auth/register` | Create an account, returns user and tokens |
| POST | `/v1/auth/login` | Returns user and tokens |
| POST | `/v1/auth/refresh` | Exchange a refresh token for a new pair |
| POST | `/v1/auth/logout` | Revoke a refresh token |
| GET / PATCH | `/v1/me` | Read or update the profile |
| POST | `/v1/me/password` | Change password, signs out everywhere |
| GET / POST | `/v1/goals` | List (`?status=ACTIVE`) or create goals |
| GET / PATCH / DELETE | `/v1/goals/:id` | Read, update or archive a goal |
| POST | `/v1/savings/deposits` | Record a deposit (needs `Idempotency-Key`) |
| GET | `/v1/savings/deposits` | Deposit history (`?limit=20&cursor=…`) |
| GET | `/v1/savings/deposits/:id` | One deposit with its split |
| GET | `/v1/savings/summary` | Totals for the dashboard |

Example:

```bash
curl -X POST localhost:3000/v1/savings/deposits \
  -H "Authorization: Bearer $TOKEN" \
  -H "Idempotency-Key: $(uuidgen)" \
  -H "Content-Type: application/json" \
  -d '{"amount": 50000, "note": "Monday sales"}'
```

```json
{
  "id": "e463f991-…",
  "amount": 50000,
  "unallocatedAmount": 0,
  "note": "Monday sales",
  "allocations": [
    { "goalId": "d314…", "goalName": "New fridge", "amount": 34627 },
    { "goalId": "b4e0…", "goalName": "Stock for Eid", "amount": 15373 }
  ]
}
```

Validation errors answer `400` with one message per field, e.g.
`"targetAmount: Too small: expected number to be >0"`.
