-- CreateEnum
CREATE TYPE "movement_kind" AS ENUM ('WITHDRAWAL', 'TRANSFER');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "general_savings" BIGINT NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "movements" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "kind" "movement_kind" NOT NULL,
    "amount" BIGINT NOT NULL,
    "from_goal_id" UUID,
    "to_goal_id" UUID,
    "note" TEXT,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "movements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "movements_user_id_created_at_idx" ON "movements"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "movements_user_id_idempotency_key_key" ON "movements"("user_id", "idempotency_key");

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_from_goal_id_fkey" FOREIGN KEY ("from_goal_id") REFERENCES "goals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "movements" ADD CONSTRAINT "movements_to_goal_id_fkey" FOREIGN KEY ("to_goal_id") REFERENCES "goals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Carry over existing general savings: until now they were the unallocated
-- parts of deposits.
UPDATE "users" SET "general_savings" = COALESCE(
  (SELECT SUM("unallocated_amount") FROM "deposits" WHERE "deposits"."user_id" = "users"."id"),
  0
);
