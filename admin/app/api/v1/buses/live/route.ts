import { noContentWithCors, jsonWithCors } from "@/lib/cors";
import { apiError } from "@/lib/api-error";
import { withRequestContext } from "@/lib/request-context";
import { listBusesForLive } from "@/lib/transit-store";

type LatLng = { lat: number; lng: number };

const FALLBACK_ROUTE: LatLng[] = [
  { lat: 23.875, lng: 90.382 },
  { lat: 23.85, lng: 90.395 },
  { lat: 23.82, lng: 90.405 },
  { lat: 23.8103, lng: 90.4125 },
];

function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}

function positionOnPath(path: LatLng[], t: number): LatLng {
  if (path.length <= 1) return path[0] ?? { lat: 23.81, lng: 90.41 };
  const segFloat = t * (path.length - 1);
  const seg = Math.min(Math.floor(segFloat), path.length - 2);
  const localT = segFloat - seg;
  const p1 = path[seg];
  const p2 = path[seg + 1];
  return {
    lat: lerp(p1.lat, p2.lat, localT),
    lng: lerp(p1.lng, p2.lng, localT),
  };
}

export async function OPTIONS(req: Request) {
  return withRequestContext(req, async () => noContentWithCors());
}

export async function GET(req: Request) {
  return withRequestContext(req, async () => {
    try {
      const buses = await listBusesForLive(12);

      const now = new Date();
      const minuteSeed = now.getMinutes() / 60;

      const payload = buses.map((bus, i) => {
        const t = (minuteSeed + i * 0.13) % 1;
        const p = positionOnPath(FALLBACK_ROUTE, t);
        return {
          id: bus.id,
          bus_code: bus.code,
          lat: p.lat,
          lng: p.lng,
          heading: Math.round((t * 360 + i * 27) % 360),
          speed_kmph: 22 + (i % 4) * 3,
          updated_at: now.toISOString(),
        };
      });

      return jsonWithCors(payload);
    } catch (error) {
      console.error("[api/buses/live] GET failed", error);
      return apiError({
        code: "service_unavailable",
        message: "Live bus data is temporarily unavailable.",
        status: 503,
      });
    }
  });
}
