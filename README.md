# diy-ha-sensor

A DIY, USB-C powered room sensor for Home Assistant, running ESPHome. It reports:

- **presence**, including a person sitting still;
- **illuminance**, with 0.1 lx resolution near darkness;
- **temperature and humidity**, kept away from the electronics' own heat;
- **diagnostics**: Wi-Fi signal, uptime, chip temperature and sensor faults.

It is meant to be cheaper than buying several commercial sensors, and to fix what the current ones get wrong. The Apollo
MSR-2 reads several degrees high and has no humidity. The Aqara FP300 reports slowly and misses people sitting still.

## Status

**Phase 0: design proposal.** Nothing is built, ordered or decided yet.

- Read [`docs/design_proposal.md`](docs/design_proposal.md) for the options, the recommendation, costs, risks and the
  open questions.
- Renders and photos will appear here once there is an enclosure (Phase 3).

| Phase | Content | State |
|---|---|---|
| 0 | Questions and design proposal | In review |
| 1 | Bill of materials and sourcing | Not started |
| 2 | ESPHome firmware and CI | Not started |
| 3 | OpenSCAD enclosure, fit-test coupons first | Not started |
| 4 | Build, calibration, validation and HA docs | Not started |
| 5 | Bring-up and revision from bench results | Not started |

## Repository layout

| Path | Contents |
|---|---|
| `docs/` | Design proposal; later the BOM, build guide, wiring, calibration, validation and HA integration |
| `CLAUDE.md` | Context and working rules for Claude sessions on this repo |
| `firmware/` | (Phase 2) ESPHome packages |
| `cad/` | (Phase 3) OpenSCAD sources, STLs and renders |

Secrets never go in the repo: `secrets.yaml` is git-ignored, and a `secrets.example.yaml` will show the keys needed.
