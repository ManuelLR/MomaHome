# Sleep (home asleep)

Detects when everybody at home is asleep from the nightstand lights, and records each
night (bedtime, wake-up, hours slept). `input_boolean.sleep_night` is the single source
of truth for "night" for other packages:

- `packages/dog`: no reminders at night, and the night does not count as "time without
  peeing / pooping / going out"; dog activity in the morning is a wake-up signal.

## Detection

- **Bedtime** (`AUT-Sleep night start`): the nightstand lights
  (`light.bedroom_nightstand_lights`, the group of both, so both must be off) go from
  on to off and stay off 10 min, between 21:00 and 04:00, with someone at home. The
  night starts when they were turned off. Fallbacks: at the *fallback bedtime* if the
  lights are not on (not used tonight; if they are on, it waits for them); at 04:00 if
  nothing happened (lights left on), backdated to the fallback bedtime.
- **Night interruptions**: before the *earliest wake-up*, turning a light on (or any
  other signal) does not end the night.
- **Wake-up** (`script.sleep_wake_up`): the first sign of life after the *earliest
  wake-up*: a nightstand light turned on, someone leaving home, or a signal from another
  package (`script.sleep_wake_up` with `woke_by: <reason>`; packages/dog sends
  `dog_activity` for a walk, meal or accident). Mornings without lights still work.
  Fallback: the *latest wake-up* (and 14:00 as a safety net if HA was down).

| Setting | Default |
|---|---|
| `input_datetime.sleep_earliest_wake` | 06:30 |
| `input_datetime.sleep_latest_wake` | 09:00 |
| `input_datetime.sleep_fallback_bedtime` | 23:30 |

The defaults are set once (`AUT-Sleep default settings`) and can then be changed from
the **Sleep** view; turn `input_boolean.sleep_defaults_applied` off to restore them.

## Data

- `sensor.sleep_last_night`: hours slept last night (`state_class: measurement`, so
  the long-term statistics keep one value per day), with the attributes `started`,
  `ended`, `woke_by` (lights / left_home / fallback / dog_activity…) and `nights` (the
  last 7 nights as `[start_ts, end_ts]`).
- `custom_templates/sleep.jinja`: `awake_hours(ts)` = hours from `ts` to now without
  the nights:
  `{% from 'sleep.jinja' import awake_hours %}{{ awake_hours(ts) | float }}`.

## UI

View **Sleep** (`/lovelace/sleep`): last night (bedtime, wake-up, what woke us up),
hours slept per night (30 days), the nights of the last 7 days and the settings.

## Limitations

- It is the night of the household (from the last one asleep to the first one awake),
  not per person.
- A light turned on after the earliest wake-up ends the night even if you go back to
  sleep.
