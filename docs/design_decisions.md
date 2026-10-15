# Design decisions

A dated log, most recent first. Each entry says what was decided, why, and on what evidence. When an entry turns out
wrong, it is corrected in place with "Correction: ..." rather than deleted. "Proposed" entries wait for Paul's review
of the PR that adds them.

## 2026-10-15: CO2 standard on every unit; no separate cellar design (decided)

Source: Paul's message in the Phase 1 session, after PR #2 opened.

- **CO2 is a standard part of every unit.** It is not a variant, so any unit can replace any other if one fails.
  Accepted cost: about €48-54 per unit for a genuine Adafruit SCD-40 [S], so about €72-85 per standard unit before
  the USB supply (`docs/bom.md` section 1).
- **No separate cellar design.** The cellar is one of the house's rooms and gets a standard unit. The DS18B20 probe
  add-on proposed below is dropped.

## 2026-10-15: Phase 1 sourcing (proposed, in the BOM PR)

- **CO2 sensor: Adafruit SCD-40 (product 5187), not the Apollo SCD40 module.**
  - The Apollo module (€23.99 at Domadoo [S]) plugs into a proprietary mezzanine connector on Apollo's own board
    (Apollo docs, "Adding CO2 to MSR-2"). That doesn't suit hand wiring.
  - The Adafruit board is genuine via DigiKey and Mouser, has STEMMA QT, and has its own 3.3 V regulator and level
    shifters (Adafruit-SCD-4x-PCB README).
  - Cost: about €47-53 each [S]. With CO2 in all 10 units, CO2 is more than half the run cost (`docs/bom.md` section 1).
- **SCD-40 power: from the XIAO's 3V3 until checked.** Adafruit's I2C pull-ups follow the board supply. Feeding it 5 V
  could put 5 V on the ESP32-C3's I2C pins.
  - Phase 2 checks Adafruit's schematic before deciding [A].
  - Phase 2 also checks the XIAO's regulator headroom. The ESP32-C3 Wi-Fi peak (350 mA) plus the SCD40 peak (175 mA)
    is about 525 mA, against a XIAO rating stated as both 500 mA and 700 mA.
- **DS18B20: genuine chips from authorised distributors only, built into probes.** A 2019 study found every probe
  bought on eBay and AliExpress counterfeit (github.com/cpetrich/counterfeit_DS18B20). The same study gives a ROM-code
  check for arrival.
  - Correction (2026-10-15): dropped. There is no separate cellar design, and the cellar gets a standard unit (entry
    above). The sourcing rule still stands if probes are ever added.
- **Spares:**
  - +2 for the cheap parts (XIAO, LD2412, the SHT45's JST cable);
  - +3 for the OPT3001 boards, whose ADDR strap is rework;
  - +1 for the expensive sensors (SHT45, SCD-40) and the SCD-40's JST cable;
  - 2 × LD2410C for a side-by-side check and as a fallback.
- **Orders:**
  - one distributor order for every genuine Seeed, Adafruit and Sensirion part;
  - one AliExpress order (Hi-Link's own store for the radars);
  - one Amazon.fr order for the USB supplies and cables.

## 2026-10-15: Paul's answers after Phase 0 (decided)

Source: Paul's message in the Phase 0 session after PR #1 merged.

- **Hardware: option B as recommended.**
  - XIAO ESP32-C3, HLK-LD2412 (LD2410C fallback), genuine SHT45, OPT3001.
  - Two-part case: main body plus a separate vented climate pod.
- **Quantity:** a run of **10** units. Some may go to the US.
- **CO2:** yes. Which rooms was left open.
  - Correction (2026-10-15): decided. CO2 is standard on every unit (entry at the top).
- **Budget:** €27-35 per unit for option B is acceptable.
- **Power:** a USB wall adapter and a USB cable per unit.
- **Cellar probe:** one of the 10 units is the cellar probe. There is no separate cellar-probe parts list.
  - Correction (2026-10-15): Paul clarified there is no separate cellar design at all. The cellar unit is a standard
    unit (entry at the top).

## 2026-10-15: Phase 0 proposal approved

- **PR #1 merged.** Paul approved and merged PR #1 (`docs/design_proposal.md` and the concept model in
  `cad/concept/`). The proposal's recommendations stand unless a later entry here changes them.
