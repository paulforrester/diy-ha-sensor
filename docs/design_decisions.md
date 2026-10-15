# Design decisions

A dated log, most recent first. Each entry says what was decided, why, and on what evidence. When an entry turns out
wrong, it is corrected in place with "Correction: ..." rather than deleted. "Proposed" entries wait for Paul's review
of the PR that adds them.

## 2026-10-15: Phase 2 firmware (proposed, in the firmware PR)

- **Pin map confirmed** against Seeed's own XIAO ESP32-C3 pinout image (github.com/Seeed-Studio/OSHW-XIAO-Series,
  `pinout/XIAO_ESP32-C3_front_pinout.png`) and ESPHome's `seeed_xiao_esp32c3` aliases:
  - I2C: D4 GPIO6 SDA, D5 GPIO7 SCL;
  - radar UART: D6 GPIO21 TX, D7 GPIO20 RX;
  - 1-Wire: D2 GPIO4.

  The order along the board edges matches the Phase 0 concept model.
- **SCD-40 power: XIAO 3V3, no board rework.** This resolves the Phase 1 open point.
  - Adafruit's SCD-41 schematic: host-side I2C pull-ups go to VIN or the board's 3.3 V regulator through SJ1, and
    the sensor supply is chosen by SJ2. With VIN = 3.3 V, the bus sits at 3.3 V whichever way the jumpers are set.
    VIN = 5 V would need SJ1 re-bridged on every board.
  - Headroom: Seeed's OSHW doc says the XIAO's 3V3 can supply 700 mA. The peak load is about 525 mA (ESP32-C3 Wi-Fi
    350 mA + SCD40 175 mA).
- **Board LEDs off.** Both Adafruit boards have a green power LED (design files):
  - SHT45: hardwired, so it is desoldered;
  - SCD-40: solder jumper SJ3 is cut.

  The XIAO has only a charge LED, not software-controlled; whether it lights on USB without a battery is checked at
  bring-up [A].
- **I2C at 100 kHz.** Conservative for the cable to the climate pod. All three sensors allow 400 kHz or more (SCD4x
  datasheet v1.7, SHT4x and OPT3001 datasheets).
- **Reporting:**
  - temperature and humidity every 30 s, every reading published;
  - illuminance polled every 1 s, sent at once on a change of at least 10 % or 0.1 lx, otherwise every 60 s;
  - CO2 every 30 s in low-power periodic mode;
  - presence on change, with ESPHome's default 1 s settle.
- **CO2 calibration.** Automatic self-calibration off; forced recalibration outdoors from a Home Assistant button. The
  reference value is a number entity, default 426 ppm. ESPHome's action stops and restarts the measurement itself
  (`scd4x.cpp`).
- **Security:**
  - one API encryption key per device;
  - OTA encrypted with the same key (ESPHome's recommended form, which also removes a separate OTA password);
  - a password-protected fallback AP.
- **Network rule.** `wifi: domain` comes from secrets.yaml, so the device is reached as `<name><dns_domain>` and the
  zone isn't in the public repo until Paul answers proposal question 9.
- **Not exposed:**
  - the radar's baud-rate select, because changing it from Home Assistant would cut the UART link;
  - the SCD40's own temperature and humidity, because they read the heated main body.
- **Optional packages, off by default, but compiled in CI so they don't rot:**
  - the 1-Wire probe;
  - the Bluetooth proxy, set to passive scanning.
- **Compiling.** The cloud session can't reach `api.registry.platformio.org`, so GitHub Actions is the authoritative
  compile check. It compiles three targets: standard, LD2410C, and standard plus both options.

## 2026-10-15: USB cable (decided)

- **Cable: white, 2 m, USB-A to USB-C, the same for every unit** (Paul). The USB-A end matches the USB-A wall adapters
  in the BOM, which avoid USB-C power negotiation entirely.

## 2026-10-15: 1-Wire socket on every unit (decided)

Source: Paul, in the Phase 1 session, after discussing what dropping the DS18B20 probes would cost.

- **What:** every unit gets a 1-Wire socket, so remote DS18B20 temperature probes can be added later. The units stay
  identical and interchangeable. No probes are bought now.
- **Why:** probes are the only way to measure temperature away from the unit:
  - wine or bottle temperature in the cellar (slow, like the wine, instead of the air that jumps when the door
    opens);
  - floor versus ceiling;
  - several racks.

  A probe on a cable is also completely clear of the unit's own heat, which makes it a temperature-only fallback if
  the climate pod misses ±0.5 °C. The socket costs well under €1 per unit [A].
- **How:**
  - XIAO D2 / GPIO4, not a strapping pin (ESPHome 2026.9.1 lists GPIO2, 8 and 9 for the C3);
  - a 4.7 kΩ pull-up to 3V3;
  - a JST-XH 3-pin header inside the main body;
  - a cable knock-out in the case (Phase 3);
  - an optional ESPHome package (`one_wire` + `dallas_temp`), off by default (Phase 2).
- **Probes, when wanted:**
  - genuine DS18B20+ chips from an authorised distributor only, built into probes, each with a pre-crimped XH pigtail;
  - a ROM-code check on arrival (cpetrich/counterfeit_DS18B20).
- **Open:** the longest reliable cable with a 4.7 kΩ pull-up is checked when the first probe is added [A].

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
  - Resolved (2026-10-15, Phase 2): 3V3 it is, with no rework, and the 700 mA regulator has headroom (entry at the
    top).
  - Phase 2 checks Adafruit's schematic before deciding [A].
  - Phase 2 also checks the XIAO's regulator headroom. The ESP32-C3 Wi-Fi peak (350 mA) plus the SCD40 peak (175 mA)
    is about 525 mA, against a XIAO rating stated as both 500 mA and 700 mA.
- **DS18B20: genuine chips from authorised distributors only, built into probes.** A 2019 study found every probe
  bought on eBay and AliExpress counterfeit (github.com/cpetrich/counterfeit_DS18B20). The same study gives a ROM-code
  check for arrival.
  - Correction (2026-10-15): dropped. There is no separate cellar design, and the cellar gets a standard unit (entry
    above). The sourcing rule still stands for future probes, which every unit can now take through its 1-Wire
    socket (entry at the top).
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
