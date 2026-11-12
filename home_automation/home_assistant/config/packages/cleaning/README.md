# Cleaning (cleaning visits)

Tracks the cleaning visits at home: blocks the automatic vacuum start during the visit,
asks through Telegram which door opening was the arrival / departure, shows the live
amount to pay in the dashboard and keeps a record of every visit in a calendar.

## One-time setup (UI)

1. **Settings → Devices & services → Add integration → Local Calendar**, twice:
   - `Cleaning` → `calendar.cleaning`: planned slots. Create a recurring event for the
     time window of the visit. If a visit is finally cancelled, delete that occurrence
     from the calendar panel ("only this event"); 1h before the slot a Telegram message
     reminds you to do it.
   - `Cleaning log` → `calendar.cleaning_log`: filled automatically with the real visits
     (`🧹 Cleaning 3h08 · 37.60 €`). Separate so it never triggers the flow.
2. Fill the helpers (they keep their value across restarts):
   - `input_number.cleaning_price_per_hour` (€/h).
   - `input_number.cleaning_ask_exit_after_hours`: if the payment was not registered,
     after these hours every door opening asks whether the visit has finished.

## Flow (`input_select.cleaning_status`)

| State | Meaning | Exits |
|---|---|---|
| `Idle` | No visit now | slot start → `Expected` |
| `Expected` | Slot active, waiting for the visit to start | each door opening asks *"Is the cleaning visit starting?"* with its own time → `In progress`; slot end or event deleted → `Idle` |
| `In progress` | Clock running | UI "Mark as paid" → `Paid`; after X h, door openings ask *"Has it finished?"* |
| `Paid` | Paid amount frozen | next door opening = departure, closed after 10 min (`↩️ Not the departure` to undo; a later opening replaces the time) |

On close (`script.cleaning_finalize`) the visit is written to `calendar.cleaning_log`
and a summary is sent. Telegram messages use `target_person: auto` (whoever is at home).

`input_select.cleaning_status` is the single source of truth: any state other than `Idle`
means a visit is expected or in progress. Use it as condition in any automation that must
behave differently. Currently used by `AUT-Vacuum` / `AUT-Vacuum start`
(packages/vacuum): the vacuum is never started automatically during a visit (a manual
start from Telegram still works, and a vacuum already running is not touched).

## UI

`input_select.cleaning_status` appears in *Cosas encendidas* (as a `simple-entity` row,
so it shows text instead of a dropdown) when not `Idle`; tapping it opens a popup
(`ui-views/utils/cleaning-card.yaml`) with the live duration/amount (computed in the
card template, refreshed every minute), the pay button and the helpers to fix times or
amounts by hand.

## Limitations

- Home Assistant has no action to delete or edit calendar events (only `create_event`
  and `get_events`; deleting is only possible from the UI), so cancelling a visit is
  done by hand from the calendar panel.
- A housekeeping automation resets a stale `Expected` state on start-up and at midnight,
  and reminds at midnight about visits left `In progress`/`Paid`.
