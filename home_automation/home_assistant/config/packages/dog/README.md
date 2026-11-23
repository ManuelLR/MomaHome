# Dog (walks diary)

Tracks the dog's walks and meals from the home presence detection: when someone leaves, Telegram
asks them whether the dog is with them; when they come back, it asks whether it peed /
pooped. Every walk is written to a calendar (the diary) and fed into daily counters
with long-term statistics: minutes walked per day ("screen time", dog version), walks,
pees, poops and accidents at home.

## One-time setup (UI)

1. **Settings → Devices & services → Add integration → Local Calendar** → `Dog log`
   → `calendar.dog_log`. Until it exists, walks are still counted but not written to the
   diary.
2. Nothing else: the settings get their defaults once (`AUT-Dog default settings`) and
   can then be changed from the **Dog** view (they keep the value; turn
   `input_boolean.dog_defaults_applied` off to restore the defaults):

   | Setting | Default |
   |---|---|
   | Daily walk goal | 60 min (0 = no evening check) |
   | Max hours without going out / peeing / pooping | 3 h / 3 h / 6 h |
   | Breakfast / dinner | 07:30 / 19:30 |
   | Walk reminder after a meal | 20 min |
   | Earliest / latest wake-up, fallback bedtime (see "Night") | 05:30 / 09:00 / 23:30 |

## Flow (`input_boolean.dog_out` + `input_select.dog_walker`)

| When | Telegram | Result |
|---|---|---|
| A person leaves home (`person.*` home → not_home) and the dog is home | *"Is the dog with you?"* → `✅ Yes (since HH:MM)` | `dog_out` on, start = time they left, walker = who pressed |
| The walker arrives home (anyone if the walker is `Someone`) | *"30 min walk. What did the dog do?"* → 💧 / 💩 / 💧💩 / 🚫 | walk closed at the arrival time (`script.dog_walk_finalize`) |
| Walk open for 2 h (arrival missed or not answered) | *"Is the dog still out?"* with the same buttons (at the walker's arrival time if already home, else now) | |
| Too long without going out / peeing / pooping (hours awake) | *"Time for a walk?"* `💧 No pee for 3.2 h (since Mon 14:50)` → `🚶 Going out now`, accidents | |
| Someone arrives home and something is overdue | the same, as *"Welcome! The dog needs to go out"* | |
| Breakfast / dinner time (not if it ate in the last 2 h) | *"Breakfast time for the dog"* → `✅ Fed`; repeated once after 45 min if nobody presses it | meal saved; refused if it already ate in the last hour (*"It already ate at 19:31 (Monica)"*) |
| X min after a meal, if it has not gone out | *"Walk after the meal?"* → `🚶 Going out now` | |
| 20:30, below the daily goal | *"Daily walk goal not reached"* | |
| 23:58 | — | all-day event `📊 85 min · 3 walks · 💧4 💩2 · ⚠️1` in the diary |

The buttons carry the real times (leaving / arrival), so answering late does not change
the figures. Other buttons: `❌ The dog is not with me` / `⏳ Still out` (keep the walk
open), `🗑️ Not a walk` (discard it without saving).

**`/dog`** typed in the bot chat: today's summary (walks, minutes vs goal, pees, poops,
last pee/poop/meal) plus the buttons that apply now: `🚶 Going out now`, `🍽️ Fed now` and `💧/💩 at home`
if the dog is home, or the "back now" buttons if it is out. Use it when the presence
detection does not see the walk (e.g. going out without the keys tracker).

Telegram replies use `script.cleaning_telegram_reply` (packages/cleaning), which is a
generic "answer callback + replace message text" helper.

### Night

While `input_boolean.dog_night` is on (everybody asleep) no reminder is sent, and that
time does not count as "time without going out / peeing / pooping"
(`custom_templates/dog.jinja`, using the last 7 nights recorded in
`sensor.dog_last_night`). So a pee at 22:00 is ~1.5 h awake at 08:00, not 10 h.

- **Bedtime**: the nightstand lights (`light.bedroom_nightstand_lights`, both) go from
  on to off and stay off 10 min, between 21:00 and 04:00, with someone at home. The night
  starts when they were turned off. Fallbacks: at the *fallback bedtime* if the lights
  are not on; at 04:00 if nothing happened (lights left on), backdated to the fallback
  bedtime.
- **Night interruptions**: before the *earliest wake-up*, turning a light on, taking
  the dog out or logging anything does not end the night (a pee at 3:00 is logged and
  resets its counter; the night goes on).
- **Wake-up**: the first sign of life after the *earliest wake-up*: a nightstand light
  turned on, someone leaving home, or any dog activity (walk, meal, accident). Mornings
  without lights still work. Fallback: the *latest wake-up* (and 14:00 as a safety net).
- `sensor.dog_last_night`: hours slept last night, with `started`, `ended` and `woke_by`
  (lights / left_home / dog_activity / fallback) to check the detection.

If nobody is home when a limit is reached, the reminder is sent to whoever arrives.

## Data

- `sensor.dog_walk_minutes_today`, `sensor.dog_walks_today`, `sensor.dog_pees_today`,
  `sensor.dog_poops_today`, `sensor.dog_accidents_today`: trigger-based, updated from
  the `dog_walk_logged` / `dog_accident_logged` events and reset at midnight.
  `state_class: measurement`, so the daily `max` is kept in the long-term statistics
  (beyond `purge_keep_days`). A walk is counted on the day it is closed.
- `sensor.dog_meals_today` (same kind of counter).
- `sensor.dog_last_pee`, `sensor.dog_last_poop`: timestamps (outside or at home);
  `sensor.dog_last_meal` (attribute `by`).
- `sensor.dog_awake_hours_since_last_walk` / `_pee` / `_poop`: hours without the night,
  updated every minute; the reminders trigger when they go above the limits.
- `calendar.dog_log`: one event per walk (`🐶 35 min · 💧💩 · Manolo`, real start/end),
  per accident (`⚠️ 💧 Pee at home`), per meal (`🍽️ Meal · Monica`) and per day
  (summary). Open the **Calendar** panel
  in week view to see at which hours it usually goes out.

## UI

View **Dog** (`/lovelace/dog`): buttons to start / end a walk or log an accident by hand
(when the presence detection is not enough), today's figures, bars of minutes walked per
day and pees/poops per day (30 days), the walks timeline of the last 7 days, the diary
and the settings. While the dog is out, *Cosas encendidas* shows "Dog out on a walk".

## Limitations

- Home Assistant cannot edit or delete calendar events: wrong entries are fixed by hand
  from the Calendar panel (the daily counters are not recalculated).
- A light turned on after the earliest wake-up ends the night even if you go back to
  sleep (only that part of the night is lost).
- The reminders fire when a limit is crossed, once; after a restart with a limit
  already exceeded they wait for the next arrival home (or the next crossing).
- Presence comes from the keys trackers (`person.*`): leaving or arriving without them
  is not seen; use `/dog` or the dashboard.
