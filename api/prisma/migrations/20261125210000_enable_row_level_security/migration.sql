-- Row-level security on every table, with no policies: roles other than the
-- tables' owner (the role the API and migrations connect as, which Postgres
-- exempts) can read or change nothing.
--
-- This protects the data if the database is ever reachable another way. On
-- Supabase, its Data API (PostgREST) would otherwise serve tables in the
-- public schema to anyone holding the project's anon key.
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "goals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "deposits" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "allocations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "movements" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "business_entries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "saving_rules" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "sms_codes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "refresh_tokens" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "revoked_refresh_token_families" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "_prisma_migrations" ENABLE ROW LEVEL SECURITY;
