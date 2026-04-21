-- CreateEnum
CREATE TYPE "ChatSenderRole" AS ENUM ('USER', 'ADMIN');

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" TEXT NOT NULL,
    "user_email" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "sender_role" "ChatSenderRole" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "chat_messages_user_email_created_at_idx" ON "chat_messages"("user_email", "created_at");

-- CreateIndex
CREATE INDEX "chat_messages_created_at_idx" ON "chat_messages"("created_at");
