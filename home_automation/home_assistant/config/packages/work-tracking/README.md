# Work Tracking

Tracks work hours using physical signals (e.g. a desk power socket, a phone work profile) with Telegram confirmation. The **Local Calendar** (`calendar.<person>_work`) is the single source of truth — every work session is a calendar event that can be manually edited, added, or deleted at any time.

## How it works

### Invariant: events never overlap in time

At any given moment, there is exactly one event in the calendar covering that time (or none). Before creating a new event, any currently open event is automatically closed at the start of the new one. This way, looking at "right now" in the calendar always returns exactly one event.

### Session lifecycle

```
Signal turns ON  (e.g. socket powered on, work profile activated)
  │
  ├─ Any currently open event → closed at this exact moment (no gap, no overlap)
  ├─ New event created: "⏰ ¿Trabajando?", start = now, end = now + 23h (placeholder)
  └─ Telegram: "Are you working?" [✅ Yes | ❌ No]

  YES → event updated: "💼 Trabajo" (workday) or "🏖️ Trabajo (especial)" (weekend/holiday)
  NO  → event deleted

Signal turns OFF  (30s debounce after signal goes low)
  │
  ├─ Currently active event closed: end = signal-off timestamp
  │    • Confirmed events (💼/🏖️): summary gets " ✓" appended
  │    • Pending events (⏰): closed but summary kept as-is (visible in calendar for review)
  └─ If another signal is still ON → new ⏰ event + Telegram (same question)
```

**No "Did you finish?" question ever.** The session end is always the moment the last signal turned off. If the auto-close was wrong (e.g. socket bumped by accident), edit the calendar event directly.

### Special days

The same `⏰ → 💼/🏖️ → ✓` lifecycle applies on weekends, public holidays, and vacation days. The event title distinguishes them (`💼` for workdays, `🏖️` for special days) based on the workday sensor at the moment of confirmation.

### End of day: compaction

At 00:30, an automation processes the previous day's confirmed events and merges consecutive sessions where the gap between them is ≤ 2 minutes (e.g. two sessions that are effectively the same because they were split by a brief signal interruption).

### Midnight sessions

If a confirmed session is still active at midnight, it is automatically split: the old event is closed at 00:00 and a new one is opened to continue into the new day.

---

## Calendar event states

The ⏰ summary encodes the day type at signal-fire time, so Start YES always sets the correct confirmed label even if the user responds the next day.

| Summary | Meaning |
|---------|---------|
| `⏰ Working?` | Signal detected on a **workday** — awaiting confirmation |
| `⏰ Working? (special)` | Signal detected on a **weekend/holiday** — awaiting confirmation |
| `💼 Working` | Confirmed working session, in progress (workday) |
| `💼 Working ✓` | Confirmed and closed (workday) |
| `🏖️ Working (special)` | Confirmed working session, in progress (special day) |
| `🏖️ Working (special) ✓` | Confirmed and closed (special day) |
| *(deleted)* | User responded NO — not a work session |

---

## Automations

| Automation | Trigger | Action |
|------------|---------|--------|
| `AUT-Work <Person> - Signal ON` | Any signal turns ON | Close any open event; create ⏰ event; send Telegram |
| `AUT-Work <Person> - Start YES` | Telegram `/work_start_yes_<person> {uid}` | Update event to 💼/🏖️ |
| `AUT-Work <Person> - Start NO` | Telegram `/work_start_no_<person> {uid}` | Delete event |
| `AUT-Work <Person> - Signal OFF` | Any signal turns OFF (30s debounce) | Close active event; if other signal still on → new ⏰ |
| `AUT-Work <Person> - Split midnight` | 00:00:00 (if active 💼 event) | Close event at midnight; open continuation |
| `AUT-Work <Person> - Compact yesterday` | 00:30:00 | Merge yesterday's consecutive sessions with gap ≤ 2 min |

### Telegram command format

The event UID is a space-separated argument in the button command:

```
/work_start_yes_<person> <uid>
/work_start_no_<person> <uid>
```

In automations: `trigger.event.data.args[0]` gives the UID.

---

## Dashboard (`ui-views/Work.yaml`)

- **Status card** — individual signals + workday sensor + current calendar event
- **This week bar chart** — ApexCharts, queries calendar REST API, confirmed events only
- **Last 30 days bar chart** — same, wider range
- **Session timeline (rangeBar)** — exact start/end per session → copy to company tracker
- **Native HA Calendar card** — view/edit/create/delete events directly

All charts use `hass.callApi('GET', 'calendars/<entity>?start=...&end=...')` with JavaScript filtering for events containing `✓`.

---

## Setup requirements

1. **Local Calendar** — create via HA UI: *Settings → Integrations → Local Calendar* → name it `<Person> Work`. Generates `calendar.<person>_work`.
2. **Telegram Bot** — must be active and receiving callbacks.
3. **HA 2024.2+** — required for `calendar.get_events` with `response_variable`.
4. **ICS Calendar Tools** — HACS custom integration ([randrcomputers/ics-calendar-tools](https://github.com/randrcomputers/ics-calendar-tools)) required for `ics_calendar_tools.update_event` and `ics_calendar_tools.delete_event`. Native `calendar.update_event`/`calendar.delete_event` don't exist as HA automation services (only WebSocket UI commands).
5. **Workday sensor** — configured via HA UI for the relevant country/region. Add vacation days there.
6. **Symlink script** — run `home_automation/scripts/HA_generate_real_config.sh` after any package changes.

---

## Adding a second person

1. Create a calendar in HA UI: `<Person2> Work` → generates `calendar.<person2>_work`
2. Copy the `manolo/` folder to `<person2>/`
3. Rename all entity and command references: `manolo` → `<person2>`
4. Run the symlink script

The session logic and automation structure are identical — only the calendar entity and Telegram commands differ.

---

## Adding new signals

Signals are referenced directly in the automations (no combined sensor needed). To add a new signal (e.g. laptop on home network):

Open `automation.yaml` and add it to the `triggers` block of both Signal ON and Signal OFF automations:

```yaml
# Signal ON triggers:
  - platform: state
    entity_id: <signal_c_entity>   # ← add the new signal entity here
    to: '<on_state>'               # e.g. 'on', 'home', etc.

# Signal OFF triggers:
  - platform: state
    entity_id: <signal_c_entity>   # ← add the new signal entity here
    to: '<off_state>'              # e.g. 'off', 'not_home', etc.
    for: {seconds: 30}
```

Also update the `other_signal_on` variable in Signal OFF to include the new signal:

```yaml
other_signal_on: >
  {% if trigger.entity_id == '<signal_a_entity>' %}
    {{ is_state('<signal_b_entity>', '<b_on_state>')
       or is_state('<signal_c_entity>', '<c_on_state>') }}
  {% elif trigger.entity_id == '<signal_b_entity>' %}
    {{ is_state('<signal_a_entity>', '<a_on_state>')
       or is_state('<signal_c_entity>', '<c_on_state>') }}
  {% else %}
    {{ is_state('<signal_a_entity>', '<a_on_state>')
       or is_state('<signal_b_entity>', '<b_on_state>') }}
  {% endif %}
```
