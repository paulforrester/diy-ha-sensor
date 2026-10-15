# Firmware (ESPHome 2026.9.1)

ESPHome configuration for the standard unit:

- XIAO ESP32-C3;
- HLK-LD2412 radar;
- SHT45 in the climate pod;
- OPT3001 lux sensor;
- SCD40 CO2 sensor;
- a 1-Wire socket.

It is built from packages. Each device file is a few lines that set a name and pull in a variant.

**Status:** every config validates with `esphome config` on ESPHome 2026.9.1. Compiling is done by CI
(`.github/workflows/ci.yml`): the cloud session that wrote this can't reach the PlatformIO registry
(`api.registry.platformio.org`). **Nothing has run on real hardware yet.**

## Layout

```
firmware/
  sense-bench.yaml          device file: the first unit, on the bench (copy per room: sense-<room>.yaml)
  secrets.example.yaml      copy to secrets.yaml (git-ignored) and fill in
  variants/
    standard.yaml           the standard unit (LD2412)
    standard-ld2410.yaml    the same with the fallback LD2410C radar
  packages/
    base.yaml               board, Wi-Fi (name + DNS domain), encrypted API and OTA, safe mode, diagnostics
    i2c.yaml                the single I2C bus (GPIO6/GPIO7, 100 kHz)
    climate_sht45.yaml      temperature, humidity, offsets
    lux_opt3001.yaml        illuminance, calibration factor
    co2_scd40.yaml          CO2, forced calibration
    radar_ld2412.yaml       presence and all radar settings
    radar_ld2410.yaml       the same for the LD2410C
    onewire_probe.yaml      OPTIONAL: a DS18B20 probe on the 1-Wire socket
    bluetooth_proxy.yaml    OPTIONAL: not recommended on a climate unit (proposal section 8)
  ci/
    ci-*.yaml               CI build targets: standard, ld2410, and standard + both options
    make_ci_secrets.sh      throwaway secrets with random keys, for CI or a local test build
```

## Pin map

From the Seeed XIAO ESP32-C3 pinout (Seeed-Studio/OSHW-XIAO-Series) and ESPHome's `seeed_xiao_esp32c3` aliases:

| XIAO pin | GPIO | Use |
|---|---|---|
| 5V (VBUS) | — | LD2412 +5V |
| 3V3 | — | SHT45, OPT3001, SCD-40, 1-Wire pull-up. Rated 700 mA (Seeed); peak load about 525 mA |
| GND | — | all |
| D4 | GPIO6 | I2C SDA: SHT45 0x44, OPT3001 0x45, SCD40 0x62 |
| D5 | GPIO7 | I2C SCL |
| D6 | GPIO21 | UART TX to radar RX |
| D7 | GPIO20 | UART RX from radar TX |
| D2 | GPIO4 | 1-Wire data (4.7 kΩ to 3V3), JST-XH socket |
| D0, D8, D9 | GPIO2, 8, 9 | unused (strapping pins) |
| D1, D3, D10 | GPIO3, 5, 10 | spare |

## What a unit shows in Home Assistant

Entity names are short so they read well inside a Home Assistant area. With `friendly_name: Bench Sense` the
temperature becomes `sensor.bench_sense_temperature`. Phase 4's `docs/ha_integration.md` will list every entity id.

| Group | Entities |
|---|---|
| Presence | Presence (occupancy), Moving target, Still target, Moving/Still distance and energy, Detection distance |
| Radar settings | Radar presence timeout, distance gates, Gate 0-13 move/still thresholds, Radar distance resolution, Radar engineering mode, Radar Bluetooth, Radar firmware, Radar restart / factory reset / read settings / start background correction. Per-gate energies are disabled by default |
| Climate | Temperature (every 30 s), Humidity, Temperature offset, Humidity offset |
| Light | Illuminance (change of at least 10 % or 0.1 lx sent at once, otherwise every 60 s), Illuminance calibration factor |
| CO2 | CO2 (every 30 s, low-power mode), CO2 calibration reference, CO2 forced calibration |
| Diagnostics | Wi-Fi signal, Uptime, ESP temperature, Status, ESPHome version, IP address, a fault sensor per I2C sensor, Restart, Restart in safe mode |

## Build and flash

1. **Install ESPHome** at the pinned version:

   ```sh
   python3 -m venv .venv && .venv/bin/pip install esphome==2026.9.1
   ```

2. **Make your secrets.** Copy `secrets.example.yaml` to `secrets.yaml` and fill it in:
   - the Wi-Fi SSID and password;
   - a fallback AP password;
   - `dns_domain` (the site zone with a leading dot);
   - one API key per device, from `openssl rand -base64 32`.

   The API key also encrypts OTA updates.
3. **First flash, over USB-C.** Run `.venv/bin/esphome run sense-bench.yaml` and choose the serial port.
4. **Network.** Create the DHCP reservation and the DNS name `<name><dns_domain>` on the router (house rule). After
   that, ESPHome reaches the unit by name only (`wifi: domain` builds `use_address`); no config holds an IP.
5. **Adopt.** In Home Assistant, add the ESPHome device by its DNS name and paste its API key.

To build from Home Assistant's ESPHome Device Builder instead, copy the whole `firmware/` folder, keeping its layout,
into the add-on's config folder.

## Bring-up checks (the first unit)

- **I2C scan.** The boot log should show `0x44` (SHT45), `0x45` (OPT3001) and `0x62` (SCD40). `0x44` twice, or no
  `0x45`, means the OPT3001's ADDR strap isn't done.
- **SHT45 serial.** The boot log prints the SHT45 serial number. It should not be 0 or `ffffffff`, and should differ
  between units (counterfeit check, proposal 4.4).
- **Radar firmware.** "Radar firmware" in Home Assistant: if it reads V1.26, the radar's configuration commands
  don't apply (esphome #13366). Swap to the LD2410C variant, or update the radar.
- **LEDs and Bluetooth.**
  - Both Adafruit boards' green LEDs are removed: SHT45 LED desoldered, SCD-40 SJ3 cut.
  - Turn the radar's Bluetooth off after tuning.
- **CO2 calibration.** Automatic self-calibration is off. After 5 days, put the unit outdoors for at least
  3 minutes, check "CO2 calibration reference" (default 426 ppm), then press "CO2 forced calibration".

Full procedures come in Phase 4: `docs/build.md`, `docs/calibration.md` and `docs/validation.md`.
