#!/usr/bin/env python3
"""Read the public SAIH Guadalquivir tables and print them as JSON.

Source: SAIH of the Confederación Hidrográfica del Guadalquivir
(https://www.chguadalquivir.es/saih/). Its legal notice allows reproduction
as long as the origin is cited. Real-time data, flagged as "not validated".

Standard library only. To debug, run it by hand:

    python3 saih_guadalquivir.py gauges A55 M09
    python3 saih_guadalquivir.py reservoirs E61 E62
    python3 saih_guadalquivir.py rain P31 M07

If the CHG changes its website, expect stations to go missing (a warning is
printed to stderr) or a clear error in the Home Assistant log.
"""

import html
import json
import re
import sys
import urllib.request

BASE_URL = "https://www.chguadalquivir.es/saih/"
GAUGES_URL = BASE_URL + "AforosTabla.aspx"    # river level/flow + official thresholds
RESERVOIRS_URL = BASE_URL + "EmbalSE.aspx"    # reservoirs of the Sevilla zone
RAIN_URL = BASE_URL + "LluviaTabla.aspx"      # rain gauges, l/m² (= mm)

# Meaning of each SAIH signal suffix (e.g. "A55_107"). It is the same code the
# website uses to draw the chart of each value.
SIGNALS = {
    "107": "level",       # m (water depth, or above sea level on some stations)
    "106": "elevation",   # m above sea level
    "211": "flow",        # m³/s at gauging stations
    "215": "flow",        # m³/s downstream of the dams (H08, H09...)
}


def download(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Home Assistant)"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def text(fragment):
    """Strip tags and whitespace: '<span>0,23</span>' -> '0,23'."""
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()


def number(value):
    """'1.234,56 hm³' -> 1234.56 ; '' -> None."""
    found = re.search(r"-?[\d.]+(,\d+)?", value)
    if not found:
        return None
    return float(found.group(0).replace(".", "").replace(",", "."))


def updated_at(page):
    """'Actualizados: 30/09/2026 20:33:07' -> '2026-09-30T20:33:07' (local time)."""
    found = re.search(r"Actualizados:\s*(\d\d)/(\d\d)/(\d{4})\s+(\d{1,2}):(\d\d:\d\d)", page)
    if not found:
        return None
    day, month, year, hour, minutes = found.groups()
    return f"{year}-{month}-{day}T{int(hour):02d}:{minutes}"


def alert(station):
    """'green', 'yellow', 'orange' or 'red' comparing value with the thresholds."""
    value = station["value"]
    if value is None or station["threshold_yellow"] is None:
        return None
    if station["threshold_red"] is not None and value >= station["threshold_red"]:
        return "red"
    if station["threshold_orange"] is not None and value >= station["threshold_orange"]:
        return "orange"
    if value >= station["threshold_yellow"]:
        return "yellow"
    return "green"


def read_gauges(codes):
    page = download(GAUGES_URL)
    data = {}
    for row in re.findall(r"<tr[\s\S]*?</tr>", page):
        cells = re.findall(r"<td[^>]*>([\s\S]*?)</td>", row)
        if len(cells) < 5:
            continue
        code = text(cells[0]).split(" ")[0]
        if code not in codes:
            continue

        station = {"name": text(cells[0])}
        # Every value is followed by a cell with its chart icon, which carries
        # the signal code: IniciaCurva('A55_107').
        for previous, cell in zip(cells, cells[1:]):
            signal = re.search(r"IniciaCurva\('" + code + r"_(\d+)", cell)
            if signal and signal.group(1) in SIGNALS:
                station[SIGNALS[signal.group(1)]] = number(text(previous))

        # Last 4 cells: yellow, orange and red thresholds, and their unit.
        station["threshold_yellow"] = number(text(cells[-4]))
        station["threshold_orange"] = number(text(cells[-3]))
        station["threshold_red"] = number(text(cells[-2]))
        station["threshold_unit"] = text(cells[-1])

        # Which measurement the thresholds apply to, and the alert it gives.
        if station["threshold_unit"] == "m³/s":
            station["value"] = station.get("flow")
        elif station["threshold_unit"] == "m.s.n.m" and "elevation" in station:
            station["value"] = station["elevation"]
        else:
            station["value"] = station.get("level")
        station["alert"] = alert(station)
        data[code] = station
    return updated_at(page), data


def read_reservoirs(codes):
    page = download(RESERVOIRS_URL)
    data = {}
    # Each reservoir is a small table with <caption>E61 Aracena</caption>.
    # There is a short and a full version; keep the one that has "Capacidad".
    for table in re.findall(r"<table[\s\S]*?</table>", page):
        caption = re.search(r"<caption[^>]*>([\s\S]*?)</caption>", table)
        if not caption or "Capacidad" not in table:
            continue
        name = text(caption.group(1))
        code = name.split(" ")[0]
        if code not in codes:
            continue

        reservoir = {"name": name}
        for row in re.findall(r"<tr[\s\S]*?</tr>", table):
            cells = [text(c) for c in re.findall(r"<td[^>]*>([\s\S]*?)</td>", row)]
            if len(cells) < 2:
                continue
            label, value = cells[0], number(cells[-1])
            if label == "Capacidad":
                reservoir["capacity"] = value     # hm³
            elif label == "Nivel":
                reservoir["level"] = value        # m above sea level
            elif label == "Volumen":
                reservoir["volume"] = value       # hm³
            elif label == "%":
                reservoir["percent"] = value      # %
            elif label == "Caudal":
                reservoir["release"] = value      # m³/s being released right now
        data[code] = reservoir
    return updated_at(page), data


def read_rain(codes):
    page = download(RAIN_URL)
    data = {}
    for row in re.findall(r"<tr[\s\S]*?</tr>", page):
        # Cells: chart icon, name, current hour, previous hour, last 12 h,
        # today, yesterday, unit.
        cells = [text(c) for c in re.findall(r"<td[^>]*>([\s\S]*?)</td>", row)]
        if len(cells) < 8:
            continue
        code = cells[1].split(" ")[0]
        if code not in codes:
            continue
        data[code] = {
            "name": cells[1],
            "current_hour": number(cells[2]),
            "previous_hour": number(cells[3]),
            "last_12h": number(cells[4]),
            "today": number(cells[5]),
            "yesterday": number(cells[6]),
        }
    return updated_at(page), data


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("gauges", "reservoirs", "rain"):
        sys.exit("Usage: saih_guadalquivir.py gauges|reservoirs|rain CODE [CODE...]")

    kind, codes = sys.argv[1], sys.argv[2:]
    if kind == "gauges":
        updated, data = read_gauges(codes)
    elif kind == "reservoirs":
        updated, data = read_reservoirs(codes)
    else:
        updated, data = read_rain(codes)

    missing = [c for c in codes if c not in data]
    if missing:
        print(f"Warning: not found in SAIH: {', '.join(missing)}", file=sys.stderr)

    print(json.dumps({"updated": updated, "data": data}, ensure_ascii=False))


if __name__ == "__main__":
    main()
