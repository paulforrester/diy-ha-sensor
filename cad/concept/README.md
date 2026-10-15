# Phase 0 concept model (not for printing)

A rough 3D model of the recommended design (option B in `docs/design_proposal.md`). It exists so the layout can be
reviewed visually. It is **not** the enclosure: Phase 3 replaces it with `common.scad`, `print_*.scad` parts, fit-test
coupons and check scripts, once the design is approved and the real parts have been measured.

## What it shows

Three printed parts:

| Part | Holds | Notes |
|---|---|---|
| Back plate | XIAO cradle, SHT45 standoffs, two keyholes, 3 mm wall feet | It crosses the air gap only as two 6 mm pillars, so heat has little path to the pod |
| Body shell | Radar rails, sealed light cell with a Ø4.5 mm aperture, USB-C opening | 3.8 mm front wall over the radar; top exhaust slots, low side intake slots |
| Pod shell | Nothing; it covers the SHT45 | Vented on the floor, front and sides; solid roof except the cable hole |

The electronics:

- the boards: XIAO ESP32-C3, LD2412, OPT3001 breakout, SHT45 breakout;
- the XIAO's external antenna;
- every wire, in the colours of `docs/images/concept/wiring_concept.svg`.

Overall size: 46 × 28 × 96 mm (W × D × H), plus the 3 mm feet.

## Renders and STLs

PNG renders are in `docs/images/concept/`. The STLs are in `stl/`; open them on GitHub to rotate them in the browser.

| File | View |
|---|---|
| `concept_assembly_front.png`, `concept_assembly_back.png` | Closed unit |
| `concept_cutaway.png` | Front walls removed |
| `concept_section.png` | Vertical cut through the centre, annotated |
| `concept_electronics.png` | Boards and wiring, labelled |
| `concept_exploded.png`, `concept_parts.png` | The three parts apart |
| `wiring_concept.svg` / `.png` | Pin-to-pin wiring (Graphviz source: `wiring_concept.dot`) |
| `stl/concept_*.stl` | Each case part, and the electronics as one mesh |

## Dimensions and their sources

Nothing has been measured with calipers yet. **[A]** marks an assumption.

| Item | Value used | Source |
|---|---|---|
| XIAO ESP32-C3 outline | 21 × 17.8 mm | Seeed wiki source on GitHub |
| XIAO PCB thickness, shield height, USB-C and U.FL position | 1.2 mm, 3 mm, centred on the short end; U.FL near the other end | [A] |
| XIAO pin order along the edges | Top row D6..D0, bottom row D7, D8, D9, D10, 3V3, GND, 5V (USB-C to the right) | From memory of Seeed's pinout [A]. Check in Phase 2 |
| XIAO pin functions | D4 = GPIO6 SDA, D5 = GPIO7 SCL, D6 = GPIO21 TX, D7 = GPIO20 RX | ESPHome 2026.9.1 `boards.py` |
| LD2412 outline | 11 × 28 mm | Hi-Link LD2412 manual V1.01 |
| LD2412 pin groups | OUT/GND/+5V at one end, TX/RX/G/3V3 at the other | Hi-Link manual. Which end is which, and the order: [A] |
| OPT3001 breakout | 15 × 13 mm; pins VCC, GND, SCL, SDA, INT, ADD in a row | Size [A]; pin names from the ESPHome docs photo |
| SHT45 breakout | 25.6 × 17.8 mm, STEMMA QT sockets at both ends | [A] |
| Antenna FPC | 10 × 34 mm | [A] |
| Radar window and gap | 3.8 mm wall, 6.2 mm antenna-to-wall | Proposal 6.3 (Hi-Link guidance, PETG εr ≈ 2.68) |
| Lux aperture | Ø4.5 mm through a locally thinned 1.6 mm wall, sensor 0.4 mm behind it | Proposal 6.4 (Vishay rule at ±45°) |

## Known simplifications

- **Fixings are placeholders.** There are no snap fits, screws or lips between the shells and the back plate; the
  shells simply sit 0.2 mm off the plate. How the radar and boards are held is only indicated.
- **Joined wires aren't modelled.** Several wires land on the same XIAO pad (3V3, GND, SDA, SCL). The real build would
  join them on a small perfboard strip or with splices. Phase 3 decides which.
- **USB-C depth.** The socket sits about 2.5 mm behind the outer face of the right wall. Whether a typical plug reaches
  it is a fit-coupon question.
- **Not included:** these come in Phase 3:
  - the CO2 sensor, now standard on every unit;
  - the 1-Wire socket and its cable knock-out (added in Phase 1);
  - the wall-mount adapters (corner wedge, shelf foot);
  - the radome and lux-window test coupons.

## Regenerate and check

Tested with OpenSCAD 2021.01 and Graphviz 2.43 (Ubuntu 24.04 `apt`); headless PNG export uses `xvfb-run`.

```sh
cad/concept/render.sh               # PNGs into docs/images/concept/, STLs into cad/concept/stl/
cad/concept/check_interference.sh   # CGAL intersection of every board and wire against every case part
```

The 2026-10-15 run of `check_interference.sh` found no overlaps. Only intended contacts remain: the XIAO in its cradle
slot and the radar in its rails, both 0.000 mm³. This only checks the model against its own numbers; the real parts
may differ.
