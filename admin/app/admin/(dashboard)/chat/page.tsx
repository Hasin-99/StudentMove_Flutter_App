import { requireRole } from "@/lib/permissions";
import { listChatConversation, listChatInbox } from "@/lib/chat-store";
import { sendChatReply } from "./actions";

type ChatPageProps = {
  searchParams?: Promise<{ email?: string }>;
};

export default async function ChatPage({ searchParams }: ChatPageProps) {
  await requireRole("transport_admin");
  const params = (await searchParams) ?? {};

  const inboxRows = await listChatInbox();
  const selectedEmail = (params.email ?? inboxRows[0]?.userEmail ?? "").trim().toLowerCase();

  const conversation = selectedEmail ? await listChatConversation(selectedEmail) : [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-zinc-900">Chat Support</h1>

      <div className="grid gap-4 lg:grid-cols-[280px_1fr]">
        <section className="rounded-xl border border-zinc-200 bg-white p-3">
          <h2 className="mb-3 px-2 text-sm font-semibold text-zinc-700">Inbox</h2>
          <div className="space-y-2">
            {inboxRows.length === 0 ? (
              <p className="px-2 py-6 text-sm text-zinc-500">No messages yet.</p>
            ) : (
              inboxRows.map((row) => (
                <a
                  key={row.userEmail}
                  href={`/admin/chat?email=${encodeURIComponent(row.userEmail)}`}
                  className={`block rounded-lg border px-3 py-2 text-sm ${
                    row.userEmail === selectedEmail
                      ? "border-teal-500 bg-teal-50"
                      : "border-zinc-200 hover:bg-zinc-50"
                  }`}
                >
                  <p className="font-medium text-zinc-800">{row.userEmail}</p>
                  <p className="mt-1 line-clamp-1 text-xs text-zinc-500">{row.text}</p>
                </a>
              ))
            )}
          </div>
        </section>

        <section className="rounded-xl border border-zinc-200 bg-white p-4">
          {selectedEmail ? (
            <>
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-zinc-900">{selectedEmail}</h2>
                <span className="rounded bg-zinc-100 px-2 py-1 text-xs text-zinc-600">
                  {conversation.length} messages
                </span>
              </div>

              <div className="mb-4 max-h-[440px] space-y-2 overflow-y-auto rounded-lg bg-zinc-50 p-3">
                {conversation.map((m) => (
                  <div
                    key={m.id}
                    className={`max-w-[78%] rounded-lg px-3 py-2 text-sm ${
                      m.senderRole === "ADMIN"
                        ? "ml-auto bg-teal-600 text-white"
                        : "bg-white text-zinc-800"
                    }`}
                  >
                    <p>{m.text}</p>
                    <p
                      className={`mt-1 text-[11px] ${
                        m.senderRole === "ADMIN" ? "text-teal-100" : "text-zinc-500"
                      }`}
                    >
                      {new Date(m.createdAt).toLocaleString()}
                    </p>
                  </div>
                ))}
              </div>

              <form action={sendChatReply} className="flex items-end gap-2">
                <input type="hidden" name="email" value={selectedEmail} />
                <textarea
                  name="message"
                  required
                  rows={3}
                  placeholder="Reply to student..."
                  className="w-full rounded-lg border border-zinc-300 px-3 py-2 text-sm"
                />
                <button
                  type="submit"
                  className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
                >
                  Send
                </button>
              </form>
            </>
          ) : (
            <p className="py-16 text-center text-sm text-zinc-500">
              Select a user from inbox to open chat.
            </p>
          )}
        </section>
      </div>
    </div>
  );
}
