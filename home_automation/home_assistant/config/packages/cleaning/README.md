# Cleaning (house cleaner visits)

Tracks the cleaner's visits: blocks the vacuum while she is (or is about to be) at home,
asks through Telegram which door opening was her arrival / departure, shows the live
amount to pay in the dashboard and keeps a record of every visit in a calendar.

## One-time setup (UI)

1. **Settings → Devices & services → Add integration → Local Calendar**, twice:
   - `Limpieza` → `calendar.limpieza`: planned slots. Create a recurring event for the
     time window she may come. Cancel/move a single occurrence from the calendar panel
     ("only this event").
   - `Limpieza registro` → `calendar.limpieza_registro`: filled automatically with the
     real visits (`🧹 Limpieza 3h08 · 37.60 €`). Separate so it never triggers the flow.
2. Fill the helpers (they keep their value across restarts):
   - `input_number.cleaning_price_per_hour` (€/h).
   - `input_number.cleaning_ask_exit_after_hours`: if the payment was not registered,
     after these hours every door opening asks whether she has left.

## Flow (`input_select.cleaning_status`)

| State | Meaning | Exits |
|---|---|---|
| `Inactiva` | Nothing planned now | slot start → `Esperada` |
| `Esperada` | Slot active, waiting for her | each door opening asks *"¿Es la limpieza?"* with its own time → `En curso` |
| `Cancelada` | "Hoy no viene" pressed (Telegram, 1h before) | slot end → `Inactiva` |
| `En curso` | Clock running | UI "Marcar como pagado" → `Pagada`; after X h, door openings ask *"¿Se ha ido?"* |
| `Pagada` | Paid amount frozen | next door opening = exit, closed after 10 min (`↩️ No era ella` to undo; a later opening replaces the time) |

On close (`script.cleaning_finalize`) the visit is written to `calendar.limpieza_registro`,
`input_datetime.vacuum_last_full_clean` is set to now (no vacuum right after) and a
summary is sent. Telegram messages use `target_person: auto` (whoever is at home).

`binary_sensor.cleaning_mode` is `on` in `Esperada`, `En curso` and `Pagada`: use it as a
condition in any automation that must behave differently. Currently used by:
- `AUT-Vacuum` / `AUT-Vacuum start` (packages/vacuum): no automatic start.
- `AUT-Cleaning mode stops vacuum`: cancels a pending start and sends the vacuum home.

## UI

`sensor.cleaning_status` appears in *Cosas encendidas* when not `Inactiva`; tapping it
opens a popup (`ui-views/utils/cleaning-card.yaml`) with the live duration/amount
(computed in the card template, refreshed every minute), the pay button and the helpers
to fix times or amounts by hand.

## Limitations

- Home Assistant has no action to delete or edit calendar events (only `create_event`
  and `get_events`; deleting is only possible from the UI). "Hoy no viene" therefore
  marks the day as `Cancelada` instead of deleting the event.
- A housekeeping automation resets stale `Esperada`/`Cancelada` states on start-up and at
  midnight, and reminds at midnight about visits left `En curso`/`Pagada`.
