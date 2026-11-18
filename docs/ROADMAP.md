# Fanikisha rebuild roadmap

Fanikisha started in 2022 as a training project: a Flutter app backed by an
Express/MySQL server. The rebuild keeps the idea (goal-based savings for small
business owners, with deposits split across goals by priority and urgency) and
replaces the implementation, which had no real authentication, stored
passwords in plain text, shared every user's data with every other user, and
calculated balances on the phone.

## Phase 1: API foundation (done)

- [x] NestJS 12 + PostgreSQL + Prisma 7 project in `api/`
- [x] Registration and login: scrypt password hashing, 15-minute access tokens,
      rotating refresh tokens with reuse detection, rate-limited auth routes
- [x] Goals: create, list, update, archive, progress and daily target
- [x] Deposits split across goals on the server, in one locked transaction,
      with idempotency keys
- [x] Allocation algorithm as a pure, unit-tested function
- [x] End-to-end tests against a real database, including concurrency and
      user-isolation cases
- [x] CI on GitHub Actions

## Phase 2: Mobile app rebuild

- [ ] New Flutter app in `mobile/` (latest stable Flutter, Material 3)
- [ ] Riverpod for state, go_router for navigation, typed API client with
      automatic token refresh, refresh token in secure storage
- [ ] Screens: welcome, sign up, log in, dashboard, goals, goal detail,
      record deposit, history, profile
- [ ] Deposit preview: show how money will be split before confirming
      (needs a `POST /v1/savings/deposits/preview` endpoint)
- [ ] Brand theme (Fanikisha green, Poppins), English and Swahili
- [ ] Widget and integration tests
- [ ] Remove the 2022 app (`lib/`, `backend/`, Firebase config)

## Phase 3: Features for business owners

- [ ] Daily sales and expense log
- [ ] Saving rules, e.g. "save 10% of each day's sales"
- [ ] Withdrawals from completed goals, and moving money between goals
- [ ] Reminders when a goal falls behind its daily target

## Phase 4: Mobile money

- [ ] Deposits from mobile money (M-Pesa, Airtel Money, Tigo Pesa) through a
      payment aggregator's sandbox, confirmed by webhook
- [ ] Reconciliation of payments against recorded deposits

## Phase 5: Production and portfolio

- [ ] Deploy the API with a managed PostgreSQL database
- [ ] OpenAPI documentation
- [ ] Demo account with sample data, screenshots and a short demo video
- [ ] Architecture diagram and write-up in the root README
