# OpenHAB Configuration — Agent Guide

This directory (`/etc/openhab`) is the configuration directory for an OpenHAB home automation installation. It is
**not** a software project — there is no build step. OpenHAB reads configuration files directly from this directory at
runtime.

Primary automation language: **JRuby DSL** via the `openhab-scripting` gem.
Key ecosystems integrated: HomeKit, Alexa, Z-Wave JS, Zigbee (via zigbee2mqtt), MQTT, Matter.

---

## Required Workflow: Plan Before Editing

**All changes to this repository must go through plan mode. No file may be created or modified without an approved plan.**

Before making any edits:

1. Enter plan mode and thoroughly explore the relevant parts of the codebase.
2. Write a plan describing what will change and why.
3. Wait for explicit user approval of the plan.
4. Only then proceed with edits.

This applies to every task — no matter how small. A one-line item change still requires an approved plan.

---

## Directory Structure

| Path | Purpose |
|------|---------|
| `automation/ruby/` | Active automation rules (20 `.rb` files) and libraries (`lib/`, 13 files) |
| `items/` | Item definitions (22 `.items` files, one per room/feature area) |
| `things/` | DSL Thing definitions (mostly managed via UI; check here first) |
| `rules/` | Legacy DSL rules directory — mostly empty; `automation/ruby/` is primary |
| `services/` | Service configuration (`.cfg` files) — **CRITICAL: see warnings below** |
| `persistence/` | Data persistence strategies (`timescaledb.persist`) |
| `transform/` | State transformation files (`.map` key→value maps, `.rb` Ruby transformers) |
| `sitemaps/` | Web UI layout (`default.sitemap`) |
| `spec/` | RSpec test suite for automation rules |
| `html/`, `sounds/`, `icons/` | Static assets |
| `Gemfile` / `Gemfile.lock` | Ruby gem dependencies |
| `.rubocop.yml` | Linting configuration |

---

## Item Naming Convention

Pattern: `Floor_Room_DeviceName_Feature_Type` where Floor is optional and used only for disambiguation or to place items in a logical hierarchy. The following prefixes are used to indicate floor level:

| Prefix | Meaning |
|--------|---------|
| `FF_` | First floor |
| `SF_` | Second floor |
| `C_` | Basement (cellar) |

Examples: `FF_Kitchen_Island_Dimmer`, `SF_Thermostat`, `C_Basement_Occupancy`, `Basement_WallOutlet_Switch`, `ExerciseRoom_BikeTrainer_Switch`

Names that are multiple words such as "Exercise Room" or "Bike Trainer" should be camel-cased without spaces as in `ExerciseRoom_BikeTrainer_Switch`.

**Groups** are used extensively for scene control and logical hierarchy:

```
All_Kitchen_Lights → Normal_Kitchen_Lights → FF_Kitchen
```

**Semantic tags** are applied for cross-ecosystem compatibility:

```
["Lightbulb"]  ["Switch"]  ["Measurement"]  ["Setpoint"]
```

Always check existing `.items` files for naming patterns before adding new items.

---

## JRuby Scripting Environment

Configured in `services/jruby.cfg`. The following are **auto-required on startup** — do not explicitly require them in rule files:

- `openhab/dsl` — core OpenHAB DSL (items, rules, triggers, timers, etc.)
- `active_support/core_ext/object/blank` — `.blank?` / `.present?`
- `active_support/core_ext/string/inflections` — `.underscore`, `.camelize`, etc.

Additional libraries must be explicitly required:

```ruby
require "zwave"        # loads automation/ruby/lib/zwave.rb
require "time_helpers" # loads automation/ruby/lib/time_helpers.rb
```

Gems used in rules are declared in the `:rules` group in `Gemfile` (currently `activesupport ~> 8.1` and `minitest ~> 5`). Do not add gems without understanding the impact on the JRuby runtime.

---

## Rooms

The rooms (or distinct areas) defined in the house are:

| Room | Floor, Outside, or Meta |
|------|-------------------------|
| Front Yard | Outside |
| Backyard | Outside |
| Garage | First Floor |
| Entrance | First Floor |
| Dining Room | First Floor |
| Upstairs aka Upstairs Hallway | Second Floor |
| Basement | Cellar |
| Family Room | First Floor |
| Exercise Room | Cellar |
| Kitchen | First Floor |
| Office | First Floor |
| Laundry Room | First Floor |
| Basement Hallway | Cellar |
| Bedroom | Second Floor |
| Hidden Room | Second Floor |
| Living Room | First Floor |
| Christmas | Meta |
| Dinah's Room | Second Floor |
| Evan's Room | Second Floor |
| Kitchen Bathroom | First Floor |
| Side Yard | Outside |

---

## Automation Rules Architecture

All active rules live in `automation/ruby/*.rb`. Rule files are named by room or feature:

```
backyard.rb       basement.rb       basement_remote.rb  bedroom.rb
entrance_lights.rb  evening_lights.rb  family_room.rb  front_lights.rb
garage.rb         holiday.rb        kitchen.rb          kitchen_bathroom.rb
laundry_room.rb   living_room.rb    lock_rules.rb       office.rb
profiles.rb       scenes.rb         sun.rb              thermostats.rb
```

**Common automation patterns:**

- Z-Wave paddle multi-click triggers: `SINGLE`, `TWO`, `THREE`, `FOUR` clicks → scene changes
- Occupancy-based automation via Hiome sensors (REST API)
- Sun position triggers for outdoor/evening lighting (`sun.rb`, `evening_lights.rb`)
- Time-of-day thermostat scheduling (`thermostats.rb`)
- LED status indicators (7-color) mapped to house state via HomeSeer

**Custom profiles** (in `profiles.rb`):

- `upcase_state` — String normalization
- `binary_open_state` — Contact sensor state inversion
- `adjust_rainin_state` — Rain sensor calibration
- `number_channel_switch` — Converts a 0/1 Number channel for a ON/OFF Switch Item
- `is_low_state` — Converts a Number channel to a ON/OFF Switch Item given a threshold configuration

---

## Library Files (`automation/ruby/lib/`)

Check these before implementing new device logic — reuse existing abstractions.

| File | Purpose |
|------|---------|
| `zwave.rb` | Z-Wave constants, thermostat modes, scene trigger helpers |
| `zigbee.rb` | Zigbee2MQTT device abstractions |
| `tasmota.rb` | Tasmota (MQTT) device helpers |
| `homekit.rb` | HomeKit integration helpers |
| `homeseer.rb` | HomeSeer LED indicator color control |
| `kwikset.rb` | Kwikset smart lock keypad event parsing (Z-Wave based) |
| `aqara_cube.rb` | Aqara Cube multi-action wireless controller |
| `awtrix3.rb` | Awtrix3 matrix display notification helpers |
| `tv_notification.rb` | Apple TV notification delivery |
| `weather.rb` | Weather Underground station integration |
| `holidays.rb` | Holiday constants used by decoration lighting rules |
| `color.rb` | RGB/XY color conversion helpers |
| `time_helpers.rb` | Time/schedule utility methods |

---

## Integrations in Use

| Integration | Protocol/Method | Notes |
|-------------|----------------|-------|
| MQTT | MQTT broker (UUID: `26bcbec1ee`) | Tasmota devices, Zigbee2MQTT bridge, Z-Wave JS communication |
| Z-Wave JS | MQTT-based | Wall switches, thermostats, locks |
| Zigbee | via zigbee2mqtt | Sensors, bulbs |
| Matter | Matter binding | Thermostats |
| Bond Home | Bond binding | Ceiling fans |
| Hiome | REST API | Occupancy counting sensors |
| Kwikset | Z-Wave (see `kwikset.rb`) | Smart lock keypad events |
| HomeKit | HomeKit binding | Apple Home bridge |
| Alexa | Alexa binding | Amazon Echo devices |
| LG WebOS | WebOS binding | TV control |
| Onkyo / Pioneer AVR | Dedicated bindings | Audio receiver control |
| Awtrix3 | MQTT | Matrix notification display |
| OpenHAB Cloud | Cloud service | Remote access |

**Reference documentation** — check these for the authoritative list of supported accessory
types, characteristics, and configuration parameters before adding or editing metadata:

- OpenHAB core docs: <https://www.openhab.org/docs/>
- Add-ons index: <https://www.openhab.org/addons/>
- HomeKit: <https://www.openhab.org/addons/integrations/homekit/>
- Matter: <https://www.openhab.org/addons/bindings/matter/>
- Alexa: <https://www.openhab.org/docs/ecosystem/alexa/>

---

## Adding New Devices

Follow this checklist when onboarding a new device:

1. **Thing** — Define in the UI, or check `things/` for existing DSL patterns; follow established Thing conventions for the binding in use.
2. **Item** — Add to the appropriate room `.items` file in `items/`; follow the `Floor_Room_DeviceName_Feature_Type` naming convention; add semantic tags for HomeKit/Alexa compatibility.
3. **Rule** — If automation is needed, add to the relevant `automation/ruby/*.rb` file (or create a new one); check `lib/` for reusable device abstractions first.
4. **Library** — If a new device type needs reusable logic, add a helper module to `automation/ruby/lib/`.
5. **Persistence** — Add the item to `persistence/timescaledb.persist` (or `timescaledb` item metadata for extended retention) if state must be persisted or restored on startup beyond the catch-all default.
6. **Transform** — Add a `.map` file to `transform/` if state mapping is needed (e.g., numeric codes → human-readable strings).

---

## Developer Workflow

### Running Tests

```bash
bundle exec rspec                               # run all specs
bundle exec rspec spec/kitchen_spec.rb          # run a single spec file
```

Tests use `openhab/rspec` (from `openhab-scripting`) which provides a mocked OpenHAB runtime. `timecop` is available for testing time-dependent rules. Each spec file corresponds to a rule file: `spec/kitchen_spec.rb` tests `automation/ruby/kitchen.rb`.

Use `spec/spec_helper.rb` as a template when creating new spec files.

### Linting

```bash
bundle exec rubocop                   # check all files
bundle exec rubocop --autocorrect     # auto-fix safe violations
```

Key rules enforced by `.rubocop.yml`:

- Double-quoted strings required
- Target Ruby version: 3.4
- Plugins: `rubocop-openhab-scripting`, `rubocop-performance`, `rubocop-rspec`
- Metrics cops: disabled
- `scripts/` directory: excluded from linting

Run rubocop before submitting any rule changes.

---

## Sensitive and Critical Files

**Do not expose credential values in responses. Do not rewrite service config files wholesale.**

| File / Pattern | Risk |
|----------------|------|
| `transform/weather_secrets.map` | Weather Underground API credentials |
| `services/openhabcloud.cfg` | OpenHAB Cloud UUID and secret |
| Any `.cfg` file containing `password`, `secret`, `token`, or `key` fields | Credentials |
| `services/*.cfg` (all) | System-critical; incorrect edits can prevent OpenHAB from starting |
| `persistence/timescaledb.persist` | Modifying persistence strategies can cause data loss or startup failures |

When changes to `services/*.cfg` are required: explain the specific field and value to change rather than rewriting the entire file.

---

## Transformation Files

- **`.map` files** — Simple key→value state mappings loaded by the Map transformation service.
  Example — `lock_user.map`: `1=Keith`, `2=Sarah`, `3=kids`
- **`.rb` files** — Ruby-based transformers (e.g., `outletinuse.rb` for outlet in-use state formatting)

---

## Persistence

- **`timescaledb.persist`** — Primary (and only) persistence strategy, via the native **TimescaleDB** addon (time-series database built on PostgreSQL), connecting to `192.168.23.50:5432/tsopenhab`. Strategies in use: `everyChange`, `restoreOnStartup`.

Retention policy: 30-day global default (`services/timescaledb.cfg`), with `retentionDays=1095` (3 years) set via `timescaledb` item metadata on long-lived sensor and energy items. Compression activates after 45 days. Items not listed explicitly in `timescaledb.persist` get `everyChange + restoreOnStartup` automatically via the catch-all `*` rule.

Items that must survive reboots (e.g., thermostat modes, switch states, LED indicator colors) are covered by the catch-all `restoreOnStartup` strategy — no explicit listing required unless the item needs extended retention.

---

## Keeping This File Up to Date

When executing any task that adds new devices, bindings, libraries, or changes structural conventions, **update this file** as part of the same task. `AGENTS.md` should always accurately reflect the current state of the repository.

---

## Model Context Protocol (MCP) Servers

### Openhab MCP Server

When working with these files information on things, items, and more can be retrieved from the OpenHAB MCP server. The
server is running on the same host as OpenHAB and is configured as an MCP server with the name `openhab`
