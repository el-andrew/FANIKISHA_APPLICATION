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

## Phase 2: Mobile app rebuild (in progress)

- [x] New Flutter app in `mobile/` (Flutter 3.44, Material 3)
- [x] Riverpod for state, go_router for navigation, API client with automatic
      token refresh, tokens in the Android Keystore / iOS Keychain
- [x] Screens: welcome, sign up, log in, dashboard, goals, goal detail,
      new/edit goal, save money, history, profile, edit profile, password
- [x] Deposit preview: `POST /v1/savings/deposits/preview` shows the split
      before confirming
- [x] Brand theme (Fanikisha green, Poppins), light and dark, English and Kiswahili
- [x] Unit and widget tests, plus an integration test that drives the real app
      against the real API (with optional screenshots)
- [ ] Kiswahili text reviewed by a native speaker
- [x] App icon (adaptive and themed on Android) and splash screen from the logo,
      light and dark
- [x] Remove the 2022 app (`lib/`, `backend/`, Firebase config); the original
      code remains in the git history (commit `0ee59b3`)

## Release essentials

Needed before the app can go on the Play Store.

- [x] Forgot password: reset with an SMS code sent to the account's verified
      phone number
- [x] Account deletion in the app (Google Play requirement): confirmed with
      the password, removes the user's goals, deposits and codes, and signs
      out every device
- [x] A web page to delete an account without the app (also a Google Play
      requirement), served by the API at `/account-deletion`
- [x] Privacy policy and terms of service, in English and Kiswahili, served by
      the API at `/privacy` and `/terms` and linked from sign-up and the
      profile (drafts)
- [x] Business details: NORTH KINGS LIMITED, registration 211059125,
      Dar es Salaam (`OPERATOR_*` in `api/.env.example`)
- [ ] Contact email for data requests (`OPERATOR_EMAIL`), the remaining
      placeholders (hosting, log and backup retention), and a legal check
      against Tanzania's Personal Data Protection Act (owner)
- [x] Android release signing set up: the key is read from a git-ignored
      `key.properties` (see mobile/README.md); release builds refuse a
      non-HTTPS API
- [ ] Create the real upload key and back it up (owner)
- [x] Offline viewing: the dashboard, goals, recent history and profile are
      saved on the phone and shown, with a banner, when offline

## Phase 3: Features for business owners

- [x] Daily sales and expense log: a Business tab with sales, expenses and
      profit for today, 7 or 30 days, a daily chart and the biggest expenses
- [x] Saving rules, e.g. "save 10% of each day's sales" (or profit): the
      dashboard shows today's target, what is saved so far, and a one-tap
      deposit for the rest
- [ ] Withdrawals from completed goals, and moving money between goals
- [ ] Reminders when a goal falls behind its daily target

## Phase 4: Mobile money

- [ ] Decide the money model: Fanikisha holding savings (likely needs a
      Bank of Tanzania licence or a licensed partner) or users keeping money
      in their own mobile-money or bank accounts while Fanikisha records and
      confirms transfers
- [x] SMS provider: [Beem](https://docs.beem.africa), using its SMS API
      (`POST https://apisms.beem.africa/v1/send`, Basic auth with the API key
      and secret, numbers as `255…` without the `+`). Fanikisha generates and
      checks codes itself rather than using Beem's OTP API, so the same sender
      also serves later messages (reminders) and the provider stays replaceable.
- [ ] Beem account set-up (owner):
  - register a sender ID, e.g. `FANIKISHA` (at most 11 characters), and wait
    for activation; Beem's default `INFO` sender ID is deactivated
  - top up SMS credit (prepaid)
  - create the API key and secret, kept only in the API's environment
  - ask Beem for staging (`dev-sms.beem.africa`) credentials, if any
- [x] Phone verification through the API, before a number can be linked to
      mobile money (replaces the 2022 app's Firebase phone check). Built and
      tested with a fake sender; the first live Beem message waits on the
      account set-up above:
  - the API sends one-time codes through an `SmsSender` interface
    (`BeemSmsSender` in production), and tests use a fake that sends nothing
  - codes are stored hashed, expire after a few minutes, and allow a limited
    number of attempts
  - sending is rate-limited per phone number and per account
  - `users.phone_verified_at` records the result; changing the number clears it
  - the app gets a code-entry screen after sign-up and in the profile
- [ ] Deposits from mobile money (M-Pesa, Airtel Money, Tigo Pesa) through a
      payment aggregator's sandbox, confirmed by webhook
- [ ] Reconciliation of payments against recorded deposits

## Phase 5: Production and portfolio

- [ ] Deploy the API with a managed PostgreSQL database
- [ ] OpenAPI documentation
- [ ] Demo account with sample data, screenshots and a short demo video
- [ ] Architecture diagram and write-up in the root README
