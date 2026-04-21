"use client";

import { useState } from "react";

type PreviewResult = {
  count: number;
  totalActiveUsers: number;
  note?: string;
};

export default function AudiencePreviewCard() {
  const [departments, setDepartments] = useState("");
  const [routes, setRoutes] = useState("");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<PreviewResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function onPreview() {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (departments.trim()) params.set("departments", departments.trim());
      if (routes.trim()) params.set("routes", routes.trim());
      const url = params.toString()
        ? `/admin/announcements/audience-preview?${params.toString()}`
        : "/admin/announcements/audience-preview";
      const res = await fetch(url, { method: "GET" });
      if (!res.ok) {
        setError(`Preview failed (HTTP ${res.status})`);
        setLoading(false);
        return;
      }
      const json = (await res.json()) as PreviewResult;
      setResult(json);
    } catch {
      setError("Preview failed");
    }
    setLoading(false);
  }

  return (
    <section className="rounded-xl border border-zinc-200 bg-white p-6">
      <h2 className="mb-3 text-lg font-medium">Audience preview</h2>
      <p className="mb-4 text-xs text-zinc-600">
        Estimate how many active users can see this notice before publishing.
      </p>
      <div className="grid gap-3 sm:grid-cols-2">
        <input
          value={departments}
          onChange={(e) => setDepartments(e.target.value)}
          placeholder="Departments, e.g. CSE, EEE"
          className="rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
        <input
          value={routes}
          onChange={(e) => setRoutes(e.target.value)}
          placeholder="Routes, e.g. Uttara - DSC"
          className="rounded-lg border border-zinc-300 px-3 py-2 text-sm"
        />
      </div>
      <div className="mt-3">
        <button
          type="button"
          onClick={onPreview}
          disabled={loading}
          className="rounded border border-teal-300 bg-teal-50 px-3 py-2 text-xs font-medium text-teal-800 hover:bg-teal-100 disabled:opacity-60"
        >
          {loading ? "Calculating..." : "Preview audience count"}
        </button>
      </div>

      {result ? (
        <div className="mt-3 rounded border border-zinc-200 bg-zinc-50 p-3 text-sm">
          Estimated audience: <span className="font-semibold">{result.count}</span> /{" "}
          {result.totalActiveUsers} active users
          {result.note ? <div className="mt-1 text-xs text-zinc-600">{result.note}</div> : null}
        </div>
      ) : null}
      {error ? <div className="mt-2 text-xs text-red-600">{error}</div> : null}
    </section>
  );
}
