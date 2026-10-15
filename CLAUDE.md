# CLAUDE.md: context for Claude sessions on `diy-ha-sensor`

Read this first. Keep it current: update it in the same PR as any change it describes.

## What this project is

A DIY, USB-C powered ESPHome room sensor for Paul's Home Assistant in Bordeaux, France. It reports **presence**
(still person as well as moving), **illuminance** (0.1 lx resolution near darkness), **temperature and humidity**
(no self-heating bias), plus diagnostics. Paul builds several units. Paul's original brief is not committed (the repo
is **public**); its requirements are restated in `docs/design_proposal.md` section 1.

## Status

- **Phase 0 (current):** questions and design proposal, `docs/design_proposal.md`. Waiting for Paul's answers and
  approval. Nothing is decided until Paul approves; then decisions go into `docs/design_decisions.md`.
- Phase 1: BOM and sourcing (`docs/bom.md`, `docs/bom.csv`). Paul orders; Claude never orders anything.
- Phase 2: firmware (`firmware/`, ESPHome packages) and CI (`.github/workflows/`).
- Phase 3: enclosure (`cad/`, OpenSCAD), fit-test coupons first.
- Phase 4: documentation (build, wiring, calibration, validation, HA integration).
- Phase 5: bring-up and revision from Paul's bench results.

## Key facts (sourced; see `docs/design_proposal.md` for the citations)

- ESPHome stable on 2026-10-15: **2026.9.1** (PyPI). It has native components for `ld2410`, `ld2412`, `ld2420`,
  `ld2450`, `sht4x`, `veml7700`, `bh1750`, `opt3001`, `tsl2591`, `ltr390`, `scd4x`, `bluetooth_proxy`, `openthread`
  (checked in the installed 2026.9.1 source).
- ESPHome `sht4x` reads the chip serial number (command 0x89) at boot and prints it in the config dump; the heater is
  off unless `heater_max_duty` > 0 (default 0.0).
- ESPHome `wifi` default `power_save_mode` on ESP32 is `light` in 2026.9.1.
- ESPHome `opt3001` defaults to I2C address 0x44, the same as the SHT45 (which exists only at 0x44). The ESP32-C3 has
  one I2C bus in ESPHome (`"NUM": 1` in the `i2c` component), so the OPT3001's ADDR pin must go to VDD (0x45).
- Reference sensors in the house: six Sonoff SNZB-02D (Zigbee T/RH), Apollo MSR-2 (LTR390 lux, LD2410B radar).
- Apollo MSR-2 measured 2026-10-15: DPS310 read 27.9 C vs SNZB-02D 21.6-24.6 C; ESP internal 45.8 C; CO2 346 ppm
  (below outdoor ~420 ppm). No humidity entity in its stock config.
- Aqara FP300 (wine cellar): reports T/RH on step change only, lux about hourly, missed a still person on the sofa.
- Existing HA automation "Arty Player" switches at **2 lx on / 1 lx off**.
- Apollo's MSR-2 firmware (`github.com/ApolloAutomation/MSR-2`, `Integrations/ESPHome/Core.yaml`) subtracts a default
  `DPS Temperature Offset` of **14.54 °C** from the DPS310, and its LTR390 updates every 60 s by default with an
  optional 5 lx "Reduce DB Reporting" delta filter.
- Vendor and retailer sites (Sensirion, TI, Vishay, Hi-Link, Espressif, Seeed, Adafruit, esphome.io, all shops) were
  blocked by the session proxy on 2026-10-15. GitHub and PyPI work. Datasheets were read from GitHub mirrors listed in
  `docs/design_proposal.md` section 11; ESPHome docs from `github.com/esphome/esphome-docs` (branch `current`).

## House rules (from Paul; follow them)

- **Don't guess.** Research (datasheets, ESPHome docs and source, vendor pages). If still unknown, say "I don't know",
  ask Paul, or design a bench test. Flag every assumption in the docs.
- **Git:** branch + PR, never commit to `main`. One topic per branch; Paul reviews and merges. Before pushing more to
  a branch, check whether its PR is merged; if so, start a new branch and PR. Don't stack PRs: every PR targets `main`.
- **Ground decisions in measured or sourced data**; record the reasoning in `docs/design_decisions.md` (dated, most
  recent first; correct earlier entries in place with "Correction: ...").
- **Verify before claiming.** CAD: render and run the check scripts. Firmware: compile (locally or in CI). Say what
  was verified and how; say plainly what is untested on real hardware.
- **Check the date** with `TZ=Europe/Paris date`; don't assume it.
- Metric units, EUR. Plain, concise explanations; lead with the conclusion.
- **Never order anything.** Paul buys all parts.
- **No secrets in the repo.** `secrets.yaml` is git-ignored; provide `secrets.example.yaml`.
- **No changes to Paul's HA** (it isn't reachable anyway). HA integration is documentation only.
- **Network rule:** every device gets a DHCP reservation and a DNS name `<name>.mulet.flypig.net`. Nothing references
  a literal LAN IP; configs use names (ESPHome `wifi: use_address:`). Paul or the home-network project creates the
  reservation; our docs give the step. Router: GL.iNet Flint 2 (OpenWrt). The 2.4 GHz SSID and its password live only
  in the git-ignored `secrets.yaml`.
- **The repo is public.** Don't commit the SSID, the router's host name, LAN addresses, MACs or anything else that maps
  the home network. The DNS zone appears only because device configs must use it (pending Paul's confirmation, see
  `docs/design_proposal.md` section 10, question 9).
- **No PETG-CF or any carbon- or metal-filled material in front of the radar.**
- Status LED off by default. No LED near or leaking into the lux sensor.
- If the cloud environment blocks something (a toolchain download, a vendor page), name the exact domain and ask Paul
  to allow it. Don't work around it.

## Environment and tools

Commands used in the cloud session (turn these into the environment setup script):

```sh
# ESPHome, pinned to the version recorded above, in a venv
python3 -m venv .venv && .venv/bin/pip install esphome==2026.9.1
.venv/bin/esphome version
```

To add in later phases (not yet run): `apt-get update && apt-get install -y openscad graphviz` for CAD export and
the wiring diagram. Record here whether it worked and the installed versions.

Network notes from the 2026-10-15 session: PyPI, github.com and raw.githubusercontent.com are reachable. The domains
blocked by the proxy are listed in `docs/design_proposal.md` section 9; Paul has been asked to allow them.

## Repo map

```
README.md                 overview and status
CLAUDE.md                 this file
docs/design_proposal.md   Phase 0: options, recommendation, costs, risks, questions for Paul
.gitignore                ignores secrets.yaml and ESPHome build output
```

Planned (later phases): `docs/bom.md`, `docs/bom.csv`, `docs/design_decisions.md`, `docs/build.md`, `docs/wiring.md`,
`docs/calibration.md`, `docs/validation.md`, `docs/ha_integration.md`, `firmware/` (ESPHome packages),
`cad/` (OpenSCAD, STLs, renders, check scripts), `.github/workflows/` (CI).
