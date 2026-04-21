<?php
/**
 * Add to routes/api.php (prefix api/v1, middleware optional).
 * Returns the JSON array shape expected by Flutter ScheduleSlot.fromJson().
 *
 * Example Eloquent (adjust namespaces):
 *
 * $rows = DB::table('schedules')
 *   ->join('routes', 'schedules.route_id', '=', 'routes.id')
 *   ->join('buses', 'schedules.bus_id', '=', 'buses.id')
 *   ->select([
 *     'routes.name as route_name',
 *     'schedules.weekday as day_index',
 *     'schedules.time_label',
 *     'schedules.date_label',
 *     'schedules.origin',
 *     'buses.code as bus_code',
 *     'schedules.university_tags',
 *   ])
 *   ->orderBy('routes.name')
 *   ->orderBy('schedules.weekday')
 *   ->orderBy('schedules.time_label')
 *   ->get();
 *
 * return response()->json($rows->map(function ($r) {
 *     return [
 *         'route_name' => $r->route_name,
 *         'day_index' => (int) $r->day_index,
 *         'time_label' => $r->time_label,
 *         'date_label' => $r->date_label,
 *         'origin' => $r->origin,
 *         'bus_code' => $r->bus_code,
 *         'university_tags' => json_decode($r->university_tags ?? '[]', true) ?: [],
 *     ];
 * }));
 */

use Illuminate\Support\Facades\Route;

Route::get('/schedules', function () {
    // TODO: replace with Eloquent query above
    return response()->json([]);
});
