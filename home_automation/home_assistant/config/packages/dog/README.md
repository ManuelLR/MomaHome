# Dog (walks diary)

Tracks the dog's walks from the home presence detection: when someone leaves, Telegram
asks them whether the dog is with them; when they come back, it asks whether it peed /
pooped. Every walk is written to a calendar (the diary) and fed into daily counters
with long-term statistics: minutes walked per day ("screen time", dog version), walks,
pees, poops and accidents at home.

## One-time setup (UI)

1. **Settings → Devices & services → Add integration → Local Calendar** → `Dog log`
   → `calendar.dog_log`. Until it exists, walks are still counted but not written to the
   diary.
2. **Settings → Entities**, set once (no `initial`, so they keep their value):
   - `input_number.dog_walk_daily_goal_minutes`: daily goal (0 = no evening check).
   - `input_number.dog_walk_reminder_hours`: max hours at home without going out before
     a reminder (between 08:00 and 23:00, only if someone is home).

## Flow (`input_boolean.dog_out` + `input_select.dog_walker`)

| When | Telegram | Result |
|---|---|---|
| A person leaves home (`person.*` home → not_home) and the dog is home | *"Is the dog with you?"* → `✅ Yes (since HH:MM)` | `dog_out` on, start = time they left, walker = who pressed |
| The walker arrives home (anyone if the walker is `Someone`) | *"30 min walk. What did the dog do?"* → 💧 / 💩 / 💧💩 / 🚫 | walk closed at the arrival time (`script.dog_walk_finalize`) |
| Walk open for 2 h (arrival missed or not answered) | *"Is the dog still out?"* with the same buttons (at the walker's arrival time if already home, else now) | |
| Too long without going out | *"Time for a walk?"* → `🚶 Going out now`, accidents | |
| 20:30, below the daily goal | *"Daily walk goal not reached"* | |
| 23:58 | — | all-day event `📊 85 min · 3 walks · 💧4 💩2 · ⚠️1` in the diary |

The buttons carry the real times (leaving / arrival), so answering late does not change
the figures. Other buttons: `❌ The dog is not with me` / `⏳ Still out` (keep the walk
open), `🗑️ Not a walk` (discard it without saving).

**`/dog`** typed in the bot chat: today's summary (walks, minutes vs goal, pees, poops,
last pee/poop) plus the buttons that apply now: `🚶 Going out now` and `💧/💩 at home`
if the dog is home, or the "back now" buttons if it is out. Use it when the presence
detection does not see the walk (e.g. going out without the keys tracker).

Telegram replies use `script.cleaning_telegram_reply` (packages/cleaning), which is a
generic "answer callback + replace message text" helper.

## Data

- `sensor.dog_walk_minutes_today`, `sensor.dog_walks_today`, `sensor.dog_pees_today`,
  `sensor.dog_poops_today`, `sensor.dog_accidents_today`: trigger-based, updated from
  the `dog_walk_logged` / `dog_accident_logged` events and reset at midnight.
  `state_class: measurement`, so the daily `max` is kept in the long-term statistics
  (beyond `purge_keep_days`). A walk is counted on the day it is closed.
- `sensor.dog_last_pee`, `sensor.dog_last_poop`: timestamps (outside or at home).
- `calendar.dog_log`: one event per walk (`🐶 35 min · 💧💩 · Manolo`, real start/end),
  per accident (`⚠️ 💧 Pee at home`) and per day (summary). Open the **Calendar** panel
  in week view to see at which hours it usually goes out.

## UI

View **Dog** (`/lovelace/dog`): buttons to start / end a walk or log an accident by hand
(when the presence detection is not enough), today's figures, bars of minutes walked per
day and pees/poops per day (30 days), the walks timeline of the last 7 days, the diary
and the settings. While the dog is out, *Cosas encendidas* shows "Dog out on a walk".

## Limitations

- Home Assistant cannot edit or delete calendar events: wrong entries are fixed by hand
  from the Calendar panel (the daily counters are not recalculated).
- Presence comes from the keys trackers (`person.*`): leaving or arriving without them
  is not seen; use `/dog` or the dashboard.
