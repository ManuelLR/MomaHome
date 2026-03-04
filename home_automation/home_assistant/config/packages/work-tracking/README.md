# Work Tracking

Tracks Manolo's work hours using physical signals (Android work profile + desk power socket) with Telegram confirmation. The **Local Calendar** (`calendar.manolo_work`) is the single source of truth — every work session is a calendar event that can be manually edited, added, or deleted at any time.

## How it works

### Session lifecycle

```
Signal ON (socket or Android work profile)
  │
  ├─ input_boolean.manolo_working → ON   (recorder captures real start time T0)
  ├─ Calendar event created: "⏰ ¿Trabajando?" (start=T0, end=T0+23h placeholder)
  └─ Telegram: "Are you working?" [✅ Yes | ❌ No]

        YES → event updated to "💼 Trabajo" (confirmed, in progress)
        NO  → event deleted, boolean reset

Signal OFF (both signals gone for 30+ seconds, session > 2 min)
  └─ Telegram: "Done working?" with signal-off time as end timestamp
               [✅ Yes, finished at HH:MM | ⏸ No, still working]

        YES → event updated to "💼 Trabajo ✓" with real end time
        NO  → session continues
```

### Calendar event states

| Summary | Meaning |
|---------|---------|
| `⏰ ¿Trabajando?` | Signal detected, awaiting user confirmation |
| `💼 Trabajo` | Session confirmed and in progress |
| `💼 Trabajo ✓` | Session closed (workday) |
| `🏖️ Trabajo (especial) ✓` | Session closed (weekend/holiday/vacation) |
| *(deleted)* | User responded NO — not a work session |

Day type (workday vs special) is determined by `binary_sensor.workday_sensor` at the moment of confirmation. Vacation days are added manually in the HA Workday integration UI.

### Retroactivity

The calendar event `start` is set to the **exact moment the physical signal fired** (T0), not when the user responds to Telegram. This means if the user confirms 30 minutes after turning on the socket, those 30 minutes are correctly counted. The `end` time is also accurate: it is captured at the moment the signal turns off and embedded in the Telegram button, so even a delayed response records the correct end time.

### Manual corrections

Because the calendar is the source of truth, any mistake can be fixed directly in HA's Calendar UI:
- **Wrong end time** → edit the event's end time
- **Missed a session** → create a new event manually with the correct times
- **False positive** → delete the `⏰ ¿Trabajando?` event or change its summary
- Metric sensors sync automatically within 5 minutes of any calendar change

---

## Entities

| Entity | Purpose |
|--------|---------|
| `binary_sensor.manolo_work_signal` | OR of all physical signals. **Add new signals here** for future remote work detection. |
| `input_boolean.manolo_working` | Live working state (ON while session active). Also stored in recorder for backup timeline. |
| `input_datetime.manolo_work_session_start` | Exact retroactive start time (T0). |
| `input_text.manolo_work_current_event_uid` | UID of the active calendar event. Used to update/delete it. |
| `input_number.manolo_work_hours_today` | Sum of today's closed sessions (synced from calendar every 5 min). |
| `input_number.manolo_work_hours_yesterday` | Yesterday's total (updated daily at 00:05). |
| `sensor.manolo_work_hours_live` | Live display: `hours_today` + current session duration. `state_class: measurement` → HA long-term statistics. |

---

## Automations

| ID | Trigger | Action |
|----|---------|--------|
| `WRK-MAN-Signal ON` | `binary_sensor.manolo_work_signal` → on (while not working) | Create calendar event, send Telegram with UID |
| `WRK-MAN-Start YES` | Telegram `/work_start_yes_manolo {uid}` | Update event to confirmed, store UID |
| `WRK-MAN-Start NO` | Telegram `/work_start_no_manolo {uid}` | Delete event, reset boolean |
| `WRK-MAN-Signal OFF` | Signal off for 30s (session > 2 min) | Send "Done?" Telegram with signal-off timestamp |
| `WRK-MAN-End YES` | Telegram `/work_end_yes_manolo {uid} {unix_ts}` | Update event end to signal-off time, close session. If signal is already ON when session closes, re-triggers `WRK-MAN-Signal ON` automatically. |
| `WRK-MAN-End NO` | Telegram `/work_end_no_manolo {uid}` | Acknowledge, keep session active |
| `WRK-MAN-Calendar sync` | Every 5 minutes | Query closed (✓) events → update `manolo_work_hours_today` |
| `WRK-MAN-Update yesterday` | 00:05 daily | Query yesterday's closed events → update `manolo_work_hours_yesterday` |
| `WRK-MAN-Split midnight` | 00:00:00 (if working) | Close current event at midnight, create new event for new day |

### Telegram command format

Commands are standard bot commands with the event UID (and optionally a Unix timestamp) as space-separated arguments:

```
/work_start_yes_manolo <uid>
/work_start_no_manolo <uid>
/work_end_yes_manolo <uid> <unix_timestamp>
/work_end_no_manolo <uid>
```

In automations, `trigger.event.data.args[0]` gives the UID and `trigger.event.data.args[1]` gives the timestamp.

---

## Dashboard (`ui-views/Work.yaml`)

- **Status card** — current session state, start time, hours today, hours yesterday
- **Signal diagnostics** — shows both physical signals and workday sensor
- **This week bar chart** — ApexCharts using HA long-term statistics (max per day)
- **Last 30 days bar chart** — same, wider range
- **Session timeline** — ApexCharts rangeBar using the Calendar REST API (`hass.callApi`), filtered to events with `✓` in summary. Shows exact start/end per session — use this to copy to your company's time tracker.
- **Native HA Calendar card** — view/edit/create events directly

---

## Setup requirements

1. **Local Calendar integration** — create via HA UI: *Settings → Integrations → Local Calendar* → name it "Manolo Work". This generates `calendar.manolo_work`.
2. **Telegram Bot** — must be active and receiving callbacks (verify with the washing machine notification).
3. **HA 2024.2+** — required for `calendar.update_event`, `calendar.delete_event`, and `calendar.get_events` with `response_variable`.
4. **Workday sensor** (`binary_sensor.workday_sensor`) — configured via HA UI for ES/AN. Add vacation days there manually.
5. **Run the symlink script** after any package changes: `home_automation/scripts/HA_generate_real_config.sh`

---

## Adding a second person (Monica)

1. Create a new calendar in HA UI: "Monica Work" → `calendar.monica_work`
2. Copy the `manolo/` folder to `monica/`
3. Rename all entity references from `manolo_work_*` to `monica_work_*`
4. Replace Telegram command names (e.g. `/work_start_yes_monica`)
5. Update `target_person: manolo` → `target_person: monica` in Telegram notify calls
6. Run the symlink script

The physical signals (`binary_sensor.manolo_work_signal`) and the rest of the logic are structurally identical — only entity names and the calendar differ.

---

## Physical signals

| Signal | Entity | Notes |
|--------|--------|-------|
| Android work profile | `binary_sensor.s23_work_profile` | Reported by the HA mobile app, very reliable |
| Desk power socket | `switch.man_001` | Also controls desk lamp and other devices |

Either signal being ON triggers the session detection. To add a new signal (e.g. laptop on home network, KDE Connect active session), add it to `binary_sensor.manolo_work_signal` in `template.yaml`:

```yaml
state: >
  {{ is_state('binary_sensor.s23_work_profile', 'on')
     or is_state('switch.man_001', 'on')
     or is_state('device_tracker.work_laptop', 'home') }}  # ← add here
```
