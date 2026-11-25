# AGENTS.md

Notes for anyone (human or AI assistant) changing the Fanikisha API.

## Stack

- NestJS 12, ESM only: relative imports end in `.js`, there is no `__dirname`
  (use `import.meta.dirname`), and tests run on Vitest (`vi.fn()`, not `jest.fn()`).
  Docs index: https://docs.nestjs.com/llms.txt
- Prisma 7 with the `pg` driver adapter. The client is generated into
  `src/generated/prisma` (git-ignored): run `npx prisma generate` after every
  schema change (`npm install` does it too).
- Validation: Zod schemas through Nest's `StandardSchemaValidationPipe`,
  attached with `@Body({ schema })`, `@Query({ schema })`, `@Param('id', { schema })`.
- Auth: `@nestjs/authentication` (pinned, pre-1.0). Every route needs a bearer
  token unless marked `@Public()`. `@CurrentUser()` gives `{ id, email }`.

## Rules that protect users' money

- Amounts are whole Tanzanian shillings: `BigInt` in the database, `number` in
  JSON (convert with `toAmount()`). Never use floats for stored money.
- Anything that changes a balance runs in one transaction and locks the rows it
  reads (`SELECT … FOR UPDATE`). The concurrent-deposit e2e test fails if it doesn't.
- Every query on user data filters by `userId`. Other users' records answer 404.
- Deposits require an `Idempotency-Key` header.
- "Today" means today in Tanzania: use `businessToday()`, never `new Date()` for dates.

## Checks before a change is done

```bash
npm run lint && npm run build && npm test && npm run test:e2e
```
