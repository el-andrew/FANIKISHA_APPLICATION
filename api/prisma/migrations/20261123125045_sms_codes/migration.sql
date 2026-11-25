-- Verification codes become general SMS codes with a purpose, so password
-- resets can use them too. Renames rather than recreates the table, keeping
-- existing rows as phone-verification codes.

CREATE TYPE "sms_code_purpose" AS ENUM ('VERIFY_PHONE', 'RESET_PASSWORD');

ALTER TABLE "phone_verifications" RENAME TO "sms_codes";
ALTER TABLE "sms_codes"
  ADD COLUMN "purpose" "sms_code_purpose" NOT NULL DEFAULT 'VERIFY_PHONE';
ALTER TABLE "sms_codes" ALTER COLUMN "purpose" DROP DEFAULT;

ALTER TABLE "sms_codes" RENAME CONSTRAINT "phone_verifications_pkey" TO "sms_codes_pkey";
ALTER TABLE "sms_codes" RENAME CONSTRAINT "phone_verifications_user_id_fkey" TO "sms_codes_user_id_fkey";

DROP INDEX "phone_verifications_user_id_created_at_idx";
DROP INDEX "phone_verifications_phone_created_at_idx";
CREATE INDEX "sms_codes_user_id_purpose_created_at_idx" ON "sms_codes"("user_id", "purpose", "created_at");
CREATE INDEX "sms_codes_phone_purpose_created_at_idx" ON "sms_codes"("phone", "purpose", "created_at");
