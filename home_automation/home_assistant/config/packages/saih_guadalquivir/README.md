# SAIH Guadalquivir → Home Assistant

River levels (flood watch around Bellavista / Jardines de Hércules and La Algaba)
and the reservoirs that supply Sevilla, in near real time (~10 min).

Replaces the old `rio_guadaira` package, which called the SAIH's internal chart
endpoint (`saihhist4.aspx`) and broke when the CHG changed it.

## Source and why this one

**SAIH Guadalquivir**, run by the Confederación Hidrográfica del Guadalquivir (CHG):
<https://www.chguadalquivir.es/saih/>. Its legal notice says: *"Salvo que se indique
lo contrario, la reproducción queda autorizada siempre que se cite su origen"*,
so cite the source. The CHG flags the data as real-time and not validated.

There is **no official API** for real-time river data in this basin. As of 2026-09,
these were checked and found not to provide it:

| Source | What it has |
|---|---|
| CHG IDE WFS (`idechg.chguadalquivir.es/geoserver`, `explotacion_saih`, `aforos`) | Station catalogue only, no measurements |
| MITECO ArcGIS (`services-eu1.arcgis.com/RvnYk1PBUJ9rrAuT`) `Embalses_Mapa`, `Caudales_Mapa` | Official JSON, but **weekly** (hydrological bulletin), 6 Guadalquivir flow stations |
| MITECO SAIH WMS (`wms.mapama.gob.es/sig/agua/saih/...`) | Station locations only, returns errors |
| datos.gob.es (SAIH Guadalquivir entries) | Portal under maintenance, contents unknown |
| embalses.net, estadoembalses.es | Scrape SAIH themselves, no public API |
| Junta de Andalucía, Ayto. Sevilla / Alcalá / La Algaba | No level sensors of their own published |
| Open-Meteo Flood API (GloFAS) | Documented API but modelled, daily, ~5 km: useless for local level |

So the least-bad option is reading the **public HTML tables** a citizen sees:

- `AforosTabla.aspx`: every river gauge with level, flow and the **official
  yellow / orange / red thresholds**.
- `EmbalSE.aspx`: Sevilla-zone reservoirs with level, volume, % and the flow
  being **released** right now.
- `LluviaTabla.aspx`: every rain gauge, rain in the current hour, previous hour,
  last 12 h, today and yesterday (l/m² = mm).

## Files

| File | Purpose |
|---|---|
| `saih_guadalquivir.py` | Downloads one table and prints JSON. Standard library only. |
| `command_line.yaml` | Runs the script → `sensor.saih_gauges_raw` and `sensor.saih_rain_raw` every 5 min, `sensor.saih_reservoirs_raw` every 10 min (state = SAIH update time, all data in the `data` attribute) |
| `template.yaml` | One sensor per gauge / rain gauge / reservoir (with official coordinates for the map), plus `sensor.saih_worst_river_alert` |
| `sensor.yaml` | `sensor.saih_*_trend`: rise/fall of each gauge over the last hour (core `derivative`) |

Dashboard: the **Rivers** view, `ui-views/Rivers.yaml`. Its schematic background is
`HA-custom-www/my_config/saih_rivers.svg` (served as `/local/my_config/saih_rivers.svg`);
the live values are mushroom template badges placed on top of it.

The radar is the AEMET integration's `image.aemet_weather_radar`. It only exists
after enabling Settings → Devices & services → AEMET → Configure →
"Gather data from AEMET weather radar".

### Reading the data

Levels are **not comparable between stations**: each point has its own channel and
its own official thresholds, set where that point overflows. An upstream gauge far
above its red while home is at red is normal. So:

- each station is judged only against its own thresholds (`alert`);
- what travels downstream shows as the **trend** of the upstream gauges (rising
  fast = a wave is coming), not as their absolute value;
- **flow** (m³/s) is the one comparable measure, but on the Guadaíra only A19 and
  A55 measure it.

The Guadaíra has **no reservoir** regulating it (Torre del Águila, in Utrera, is
on the Salado de Morón, which drains towards Lebrija), so it rises with rain in
its basin: watch the rain gauges and the radar.

## Debugging

Run the script by hand, on the host or inside the container:

```bash
python3 saih_guadalquivir.py gauges A55 M09
python3 saih_guadalquivir.py reservoirs E61 E62
python3 saih_guadalquivir.py rain P31 M07
docker compose exec home-assistant python3 /config/packages/saih_guadalquivir/saih_guadalquivir.py gauges A55
```

- A code missing from the output prints `Warning: not found in SAIH: ...` on stderr.
  Either the code is wrong or the CHG renamed or changed the table.
- A network or HTTP error shows up as a traceback in the Home Assistant log
  (`homeassistant.components.command_line`).
- Values are identified by the SAIH **signal code** that follows each value on
  the page (`IniciaCurva('A55_107')`), not by column position. The meaning of
  each suffix is in `SIGNALS` in the script.

## Stations

| Code | Where | Why | Measures (thresholds Y / O / R) |
|---|---|---|---|
| A55 | Guadaíra, Sevilla | Next to home | level m (2 / 3 / 4) |
| A19 | Guadaíra, Alcalá (Pte. Sifón) | Upstream, early warning | level m (2.6 / 3.9 / 5.2) |
| M54 | Guadaíra, Alcalá | Upstream | level m (6 / 7.5 / 9) |
| M07 | Guadaíra, Arahal | Far upstream, earliest warning | level m (2 / 3 / 4) |
| M09 | Guadalquivir, Sevilla | City (tidal) | m a.s.l. (3 / 3.6 / 4.5) |
| H09 | Alcalá del Río dam | Just upstream of La Algaba | flow m³/s (1500 / 2300 / 3000) |
| H08 | Cantillana dam | Further upstream | flow m³/s (1000 / 1700 / 2300) |
| A33 | Rivera de Huelva, Guillena | Joins the Guadalquivir near La Algaba | level m (3 / 4.2 / 4.8) |

Thresholds are read live from the page, not hard-coded. Reservoirs: E58 Melonares,
E61 Aracena, E62 Zufre, E63 La Minilla, E64 Cala, E65 El Gergal.

Rain gauges: Guadaíra basin P31 Morón, P67 Marchena, M07 Arahal, P65 Utrera,
P28 El Viso del Alcor, M09 Sevilla; Rivera de Huelva basin (La Algaba) M25 Almadén
de la Plata, E64 Cala, E63 La Minilla.

**To add a station:** find its code in the
[list of control points](https://www.chguadalquivir.es/saih/Doc/Listado_puntos_de_control.pdf)
(the code must appear on `AforosTabla.aspx` or `LluviaTabla.aspx`), add it to the
command in `command_line.yaml`, and copy a sensor block in `template.yaml`, with
its coordinates from the CHG catalogue:
`https://idechg.chguadalquivir.es/geoserver/ows?service=WFS&version=1.1.0&request=GetFeature&typeName=ggiscloud_root:explotacion_saih`.

## Ideas for later

- **Telegram alert** when `sensor.saih_worst_river_alert` leaves `green`
  (`script.telegram_notify`, as in `packages/emasesa`).
- **EMASESA**: the integration already has one sensor per reservoir (daily, no
  releases), disabled by default. Enable them from the device page as a backup source.
- **Faster rain, less reliable**: the core Meteoclimatic integration (amateur
  stations, every few minutes, daily total only). There are stations in Morón,
  Arahal, Alcalá de Guadaíra, El Viso del Alcor, Cantillana and Sevilla.
- **Rain warnings**: the AEMET / Meteoalarm core integrations.
- **Small web / map**: MITECO publishes the official flood zones (SNCZI) as
  `Zonas_de_Inundacion` on the same ArcGIS server. That is useful to show
  "how far the water could reach" next to the gauges.
- **Ask for a real API**: request the SAIH real-time data as open data through
  datos.gob.es ("solicitud de datos") or the CHG. The EU Open Data Directive
  (2019/1024) asks for dynamic data to be offered through an API.
- The CHG also has an official Telegram bot, `@chgsaih_bot`, for manual queries.
