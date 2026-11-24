-- CreateEnum
CREATE TYPE "saving_basis" AS ENUM ('SALES', 'PROFIT');

-- CreateTable
CREATE TABLE "saving_rules" (
    "user_id" UUID NOT NULL,
    "basis" "saving_basis" NOT NULL,
    "percent" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "saving_rules_pkey" PRIMARY KEY ("user_id")
);

-- AddForeignKey
ALTER TABLE "saving_rules" ADD CONSTRAINT "saving_rules_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
