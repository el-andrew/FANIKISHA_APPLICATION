-- CreateEnum
CREATE TYPE "entry_type" AS ENUM ('SALE', 'EXPENSE');

-- CreateTable
CREATE TABLE "business_entries" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" "entry_type" NOT NULL,
    "amount" BIGINT NOT NULL,
    "category" TEXT,
    "note" TEXT,
    "occurred_on" DATE NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "business_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "business_entries_user_id_occurred_on_idx" ON "business_entries"("user_id", "occurred_on");

-- CreateIndex
CREATE UNIQUE INDEX "business_entries_user_id_idempotency_key_key" ON "business_entries"("user_id", "idempotency_key");

-- AddForeignKey
ALTER TABLE "business_entries" ADD CONSTRAINT "business_entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
