// DIY HA sensor: Phase 0 CONCEPT model. NOT FOR PRINTING.
//
// Purpose: let Paul see the proposed layout (docs/design_proposal.md, sections 6 and 7) in 3D:
// where each board sits, how it is wired, and the three case parts. Board sizes come from
// datasheets and vendor pages, or are assumptions marked [A]; none has been measured.
// Phase 3 replaces this file with common.scad + print_*.scad parts, fit coupons and checks.
//
// Axes (OpenSCAD's own front view): X = left to right as seen from the room,
// Y = depth (0 = front face, towards the wall is +Y), Z = height (0 = bottom of the climate pod).
//
// Render with cad/concept/render.sh. Select what to draw with -D 'view="..."':
//   assembly | cutaway | section | exploded | electronics | back
//   part_back_plate | part_body_shell | part_pod_shell | part_electronics   (STL export)

view = "assembly";
$fn = 40;

// ---------------------------------------------------------------- envelope
W        = 46;     // width
D        = 28;     // depth, front face to the wall face of the back plate
tb       = 2.5;    // back plate thickness
feet     = 3;      // stand-off from the wall (air behind the whole unit)
wall     = 2;      // side, top and bottom walls
front_t  = 3.8;    // radar window: half-wavelength in PETG, εr ≈ 2.68 (proposal 6.3)
radar_gap = 6.2;   // antenna face to inside of the front wall: half-wavelength in air

pod_h    = 24;               // climate pod height
gap_h    = 10;               // open air gap between pod and body
body_z0  = pod_h + gap_h;    // 34
body_h   = 62;
H        = body_z0 + body_h; // 96

pillar_w = 6;      // the only plastic bridging the air gap: two back-plate pillars
fit      = 0.2;    // assembly clearance between the shells and the back plate
cable_x  = 9;      // SHT45 cable hole through the pod roof and the body floor
cable_y  = 19;

// ---------------------------------------------------------------- boards
// XIAO ESP32-C3: 21 x 17.8 mm (Seeed wiki). Thickness and part heights [A].
xiao_l = 21;  xiao_w = 17.8; xiao_t = 1.2; xiao_parts = 3.0;
// HLK-LD2412: 11 x 28 mm (Hi-Link manual V1.01). PCB thickness [A].
rad_l  = 28;  rad_w  = 11;   rad_t  = 1.6;
// Generic OPT3001 breakout: size not found, assumed [A].
opt_l  = 15;  opt_w  = 13;   opt_t  = 1.6;
// Adafruit SHT45 breakout (product 5665): size assumed [A].
sht_l  = 25.6; sht_w = 17.8; sht_t  = 1.6;

// Board positions (minimum corner of each PCB).
xiao_pos = [W - wall - 1.5 - xiao_l, D - tb - 3 - xiao_t, body_z0 + wall + 2.5]; // USB-C points to +X (right side)
rad_y    = front_t + radar_gap;                         // antenna face, Y = 10.0
rad_pos  = [(W - rad_l) / 2, rad_y, body_z0 + 24.5];    // Z 58.5 .. 69.5
lux_wall = 1.6;                                         // front wall thinned locally at the light cell
lux_c    = [W / 2, 0, H - wall - 8];                    // light-cell centre (X, -, Z) = (23, -, 86)
opt_pos  = [lux_c[0] - opt_l / 2, lux_wall + 0.4 + 0.65, lux_c[2] - opt_w / 2];
sht_pos  = [(W - sht_l) / 2, D - tb - 5 - sht_t, 3.1];

// Wire colours (also used in docs/images/concept/wiring_concept.svg).
C5V = "red"; CGND = "black"; C3V3 = "orange"; CSDA = "royalblue"; CSCL = "gold";
CTX = "limegreen"; CRX = "white"; CCOAX = "dimgray";

// ---------------------------------------------------------------- helpers
module wire(pts, c, d = 1.0) {
    color(c) for (i = [0 : len(pts) - 2])
        hull() { translate(pts[i]) sphere(d = d, $fn = 12); translate(pts[i + 1]) sphere(d = d, $fn = 12); }
}

module label(txt, at, side = -1, size = 2.4) {
    // Text beside the unit (side -1 = left, +1 = right), facing the front, with a leader to `at`.
    tx = side < 0 ? -10 : W + 10;
    color("black") translate([tx, -2, at[2]]) rotate([90, 0, 0]) linear_extrude(0.3)
        text(txt, size = size, font = "Liberation Sans:style=Bold", halign = side < 0 ? "right" : "left", valign = "center");
    wire([[tx - side * 1.5, -2, at[2]], [side < 0 ? -1 : W + 1, -2, at[2]], at], "gray", 0.35);
}

// ---------------------------------------------------------------- board models
// XIAO pin X positions: 7 castellated pins per long edge, 2.54 mm pitch, centred.
// Pin order from memory of Seeed's pinout [A]; check against the Seeed pinout in Phase 2.
// With USB-C to the right: top row D6..D0 (left to right), bottom row D7, D8, D9, D10, 3V3, GND, 5V.
function xiao_pin_x(i) = xiao_pos[0] + (xiao_l - 6 * 2.54) / 2 + i * 2.54;  // i = 0 at the left end
xiao_top_z = xiao_pos[2] + xiao_w - 1.0;
xiao_bot_z = xiao_pos[2] + 1.0;
xiao_pad_y = xiao_pos[1] - 0.3;                         // front (component) side of the XIAO PCB
function xiao_top(i) = [xiao_pin_x(i), xiao_pad_y, xiao_top_z];
function xiao_bot(i) = [xiao_pin_x(i), xiao_pad_y, xiao_bot_z];
// Signals (ESPHome 2026.9.1 boards.py, seeed_xiao_esp32c3): D4 = GPIO6 = SDA, D5 = GPIO7 = SCL,
// D6 = GPIO21 = TX, D7 = GPIO20 = RX.
P_TX = xiao_top(0); P_SCL = xiao_top(1); P_SDA = xiao_top(2);
P_RX = xiao_bot(0); P_3V3 = xiao_bot(4); P_GND = xiao_bot(5); P_5V = xiao_bot(6);

module xiao() {
    translate(xiao_pos) {
        color("#1b1b1b") cube([xiao_l, xiao_t, xiao_w]);                                      // PCB (black)
        color("silver") translate([3, -xiao_parts, 2.5]) cube([12, xiao_parts, xiao_w - 5]);  // shield can
        color("silver") translate([xiao_l - 6.5, -3.2, (xiao_w - 8.94) / 2]) cube([7.5, 3.2, 8.94]); // USB-C, 1 mm overhang
        color("gold") translate([2.2, -0.8, xiao_w / 2 - 1]) cube([2, 0.8, 2]);               // U.FL
        for (i = [0 : 6]) for (z = [1.0, xiao_w - 1.0])
            color("gold") translate([xiao_pin_x(i) - xiao_pos[0] - 0.8, -0.05, z - 0.8]) cube([1.6, 0.1, 1.6]);
    }
}

// LD2412 pins: OUT/GND/+5V at one short end, TX/RX/G/3V3 at the other (Hi-Link manual).
// Which end is which, and the pin order, are assumptions [A]. Wires solder on the back (+Y) side.
rad_back = rad_y + rad_t + 0.2;
R_5V  = [rad_pos[0] + 1.27, rad_back, rad_pos[2] + rad_w / 2 + 2.54];
R_GND = [rad_pos[0] + 1.27, rad_back, rad_pos[2] + rad_w / 2];
R_TX  = [rad_pos[0] + rad_l - 1.27, rad_back, rad_pos[2] + rad_w / 2 + 3.81];
R_RX  = [rad_pos[0] + rad_l - 1.27, rad_back, rad_pos[2] + rad_w / 2 + 1.27];

module ld2412() {
    translate(rad_pos) {
        color("#2d6a3e") cube([rad_l, rad_t, rad_w]);                                  // PCB
        color("#c9a227") for (i = [0 : 3]) translate([6 + i * 4.4, -0.05, 2.2])        // antenna patches (front)
            cube([3.0, 0.05, rad_w - 4.4]);
        color("#333") translate([8, rad_t, 2]) cube([12, 1.5, 7]);                     // back-side parts
        for (p = [[1.27, rad_w / 2 - 2.54], [1.27, rad_w / 2], [1.27, rad_w / 2 + 2.54],
                  [rad_l - 1.27, rad_w / 2 - 3.81], [rad_l - 1.27, rad_w / 2 - 1.27],
                  [rad_l - 1.27, rad_w / 2 + 1.27], [rad_l - 1.27, rad_w / 2 + 3.81]])
            color("gold") translate([p[0], rad_t / 2, p[1]]) rotate([90, 0, 0]) cylinder(d = 1.4, h = rad_t + 0.3, center = true);
    }
}

// OPT3001 breakout pins along the lower edge: VCC, GND, SCL, SDA, INT, ADD (ESPHome docs photo). Wires on the back.
function opt_pin(i) = [opt_pos[0] + opt_l / 2 + (i - 2.5) * 2.54, opt_pos[1] + opt_t + 0.2, opt_pos[2] + 1.6];
module opt3001() {
    translate(opt_pos) {
        color("#5b2c83") cube([opt_l, opt_t, opt_w]);                                  // PCB (purple)
        color("#111") translate([opt_l / 2 - 1, -0.65, opt_w / 2 - 1]) cube([2, 0.65, 2]); // 2 x 2 mm sensor
    }
    for (i = [0 : 5]) color("gold") translate(opt_pin(i) - [0, 0.2, 0]) rotate([90, 0, 0]) cylinder(d = 1.3, h = opt_t + 0.3, center = true);
}

// SHT45 breakout: STEMMA QT sockets at both ends; the cable plugs into the left one.
module sht45() {
    translate(sht_pos) {
        color("#1f3f8f") cube([sht_l, sht_t, sht_w]);                                  // PCB (blue)
        color("#ddd") translate([sht_l / 2 - 0.75, -0.5, sht_w / 2 - 0.75]) cube([1.5, 0.5, 1.5]); // 1.5 x 1.5 mm sensor
        color("white") for (x = [0.5, sht_l - 6.5]) translate([x, -3.0, sht_w / 2 - 2.1]) cube([6, 3.0, 4.2]); // JST-SH sockets
    }
}

// XIAO's included external antenna (FPC), stuck to the inside of the left wall [A: size].
module antenna() {
    color("#c8a24a") translate([wall + 0.05, 13.5, body_z0 + 24]) cube([0.25, 10, 34]);
}

// ---------------------------------------------------------------- wiring
// Every wire reaches a XIAO pad from the front, at the pad's height. Runs go in a corridor between
// the radar's back (Y ~13) and the XIAO's parts (Y ~18).
yc = 15.5;
function to_pad(p, y) = [[p[0], y, p[2]], p];
module wiring() {
    // 5 V and GND to the radar (left end), along the left side.
    wire(concat([[6.5, yc, R_5V[2]], [6.5, yc, P_5V[2]]], to_pad(P_5V, yc)), C5V);
    wire([R_5V, [6.5, yc, R_5V[2]]], C5V);
    wire(concat([R_GND, [7.7, yc + 1.2, R_GND[2]], [7.7, yc + 1.2, P_GND[2] + 0.6]], to_pad(P_GND + [0, 0, 0.6], yc + 1.2)), CGND);
    // UART: XIAO TX (D6) -> radar RX; radar TX -> XIAO RX (D7).
    wire(concat([R_RX, [R_RX[0], yc, R_RX[2]], [R_RX[0], yc, P_TX[2]]], to_pad(P_TX, yc)), CTX);
    wire(concat([R_TX, [R_TX[0] + 1.5, yc - 1.2, R_TX[2]], [R_TX[0] + 1.5, yc - 1.2, rad_pos[2] - 2.5],
                 [xiao_pos[0] - 2, yc - 1.2, rad_pos[2] - 2.5], [xiao_pos[0] - 2, yc - 1.2, P_RX[2]]], to_pad(P_RX, yc - 1.2)), CRX);

    // OPT3001: out through the light-cell back wall, behind the radar, to the XIAO.
    hole = [lux_c[0], 9.2, lux_c[2] - 4];
    rt   = [hole[0], yc + 0.5, rad_pos[2] + rad_w + 3];
    wire(concat([opt_pin(2), hole - [0, 3, 0], hole, rt, [P_SCL[0], yc + 0.5, P_SCL[2] + 1.5]], to_pad(P_SCL, yc + 0.5)), CSCL, 0.8);
    wire(concat([opt_pin(3), hole + [0.7, -3, 0], hole + [0.7, 0, 0], rt + [0.7, 0, 0], [P_SDA[0], yc + 1.1, P_SDA[2] + 1.5]], to_pad(P_SDA, yc + 1.1)), CSDA, 0.8);
    wire(concat([opt_pin(0), hole + [-0.7, -3, 0], hole + [-0.7, 0, 0], rt + [-0.7, 0, 0], [xiao_pos[0] - 1, yc + 2, rad_pos[2] - 2.5],
                 [xiao_pos[0] - 1, yc + 2, P_3V3[2]]], to_pad(P_3V3, yc + 2)), C3V3, 0.8);
    wire(concat([opt_pin(1), hole + [-1.4, -3, 0], hole + [-1.4, 0, 0], rt + [-1.4, 0, 0], [xiao_pos[0] - 0.2, yc + 2.6, rad_pos[2] - 2.5],
                 [xiao_pos[0] - 0.2, yc + 2.6, P_GND[2] - 0.6]], to_pad(P_GND - [0, 0, 0.6], yc + 2.6)), CGND, 0.8);
    // ADD strapped to VCC -> I2C address 0x45 (the SHT45 owns 0x44).
    wire([opt_pin(5), opt_pin(5) + [0, 1.2, 0], opt_pin(0) + [0, 1.2, 0], opt_pin(0)], C3V3, 0.6);

    // SHT45: STEMMA QT cable up through the pod roof, across the air gap, in through the body floor,
    // then to the XIAO's 3V3, GND (bottom row) and SDA, SCL (top row).
    plug = [sht_pos[0] + 3.5, sht_pos[1] - 3.2, sht_pos[2] + sht_w / 2];
    for (k = [0 : 3]) {
        c   = [C3V3, CGND, CSDA, CSCL][k];
        dx  = (k - 1.5) * 0.9;
        tgt = [P_3V3, P_GND, P_SDA, P_SCL][k] + [0, 0, k < 2 ? -0.3 : 0.3];
        zr  = k < 2 ? tgt[2] : tgt[2] + 2.2;
        wire(concat([plug + [dx, 0, 0], [cable_x + dx, plug[1] - 1, plug[2]], [cable_x + dx, cable_y, pod_h - 3],
                     [cable_x + dx, cable_y, zr], [tgt[0] + dx * 0.3, cable_y, zr]], to_pad(tgt + [dx * 0.3, 0, 0], cable_y)), c, 0.7);
    }

    // U.FL coax to the antenna.
    wire([xiao_pos + [3.2, -0.8, xiao_w / 2], [xiao_pos[0] + 3.2, 19.8, xiao_pos[2] + xiao_w / 2],
          [xiao_pos[0] - 1.5, 19.8, xiao_pos[2] + xiao_w / 2], [wall + 1.5, 19.8, body_z0 + 40], [wall + 0.9, 18.5, body_z0 + 40]], CCOAX, 1.13);
}

module electronics() { xiao(); ld2412(); opt3001(); sht45(); antenna(); wiring(); }

// ---------------------------------------------------------------- case parts
usb_c = [xiao_pos[1] - 1.6, xiao_pos[2] + xiao_w / 2];  // USB-C plug centre (Y, Z)

module keyhole(x, z) {
    translate([x, D - tb - 0.1, z]) rotate([-90, 0, 0]) {
        cylinder(d = 8.5, h = tb + 0.2);                                   // screw head goes in
        hull() for (dz = [0, 6]) translate([0, -dz, 0]) cylinder(d = 4.2, h = tb + 0.2); // then slides down onto the shank
    }
}

// Part 1: back plate. Carries the XIAO cradle, the SHT45 standoffs, keyholes and wall stand-off feet.
// Across the air gap it is only two narrow pillars, so heat has almost no conduction path to the pod.
module back_plate() {
    difference() {
        union() {
            translate([0, D - tb, body_z0]) cube([W, tb, body_h]);
            translate([0, D - tb, 0]) cube([W, tb, pod_h]);
            for (x = [0, W - pillar_w]) translate([x, D - tb, pod_h - 0.01]) cube([pillar_w, tb, gap_h + 0.02]);
            // wall stand-off feet (keep a 3 mm air layer behind the unit)
            for (x = [5, W - 5]) for (z = [5, pod_h - 5, body_z0 + 5, H - 5])
                translate([x, D, z]) rotate([-90, 0, 0]) cylinder(d = 6, h = feet);
            // XIAO cradle: end blocks with front lips at the two short ends. The long edges carry the
            // castellated pads, so nothing grips them. The USB-C end is gripped at its corners only.
            translate([xiao_pos[0] - 1.2, xiao_pos[1] - 0.6, xiao_pos[2] - 0.5]) difference() {
                cube([1.8, D - tb - xiao_pos[1] + 0.6 + 0.01, xiao_w + 1]);
                translate([1.2, 0.6, -0.1]) cube([1, xiao_t, xiao_w + 1.2]);          // PCB slot
            }
            for (z = [xiao_pos[2] - 0.5, xiao_pos[2] + xiao_w - 3]) translate([xiao_pos[0] + xiao_l - 0.6, xiao_pos[1] - 0.6, z])
                difference() {
                    cube([1.8, D - tb - xiao_pos[1] + 0.6 + 0.01, 3.5]);
                    translate([-0.1, 0.6, (z < xiao_pos[2] ? 0.5 : -0.1)]) cube([0.7, xiao_t, 3.1]);
                }
            // ribs behind the XIAO, so it can't be pushed back
            for (z = [xiao_pos[2] + 3, xiao_pos[2] + xiao_w - 4.2]) translate([xiao_pos[0] + 2, xiao_pos[1] + xiao_t, z])
                cube([xiao_l - 4, D - tb - xiao_pos[1] - xiao_t + 0.01, 1.2]);
            // SHT45 standoffs (5 mm, behind the board's corners)
            for (x = [sht_pos[0] + 2.5, sht_pos[0] + sht_l - 2.5]) translate([x, sht_pos[1] + sht_t, sht_pos[2] + sht_w - 2.5])
                rotate([-90, 0, 0]) cylinder(d = 5, h = 5.01);
        }
        for (z = [rad_pos[2] + rad_w / 2, H - 12]) keyhole(W / 2, z);
    }
}

// Part 2: body shell (front, sides, top, bottom of the main body). Holds the radar and the light cell.
module body_shell() {
    difference() {
        union() {
            difference() {
                translate([0, 0, body_z0]) cube([W, D - tb - fit, body_h]);
                translate([wall, front_t, body_z0 + wall]) cube([W - 2 * wall, D, body_h - 2 * wall]);
            }
            // light cell: opaque box around the OPT3001, open only to the aperture
            translate([lux_c[0] - 10, lux_wall, lux_c[2] - 8.5]) difference() {
                cube([20, 8.6 - lux_wall, H - wall - (lux_c[2] - 8.5)]);
                translate([1.6, -0.01, 1.6]) cube([16.8, 7 - lux_wall + 0.01, 20]);
            }
            // radar holder: rails along the radar's long edges, with a slot for the PCB
            for (z = [rad_pos[2] - 1.6, rad_pos[2] + rad_w]) translate([wall, front_t, z])
                difference() {
                    cube([W - 2 * wall, rad_y + rad_t + 1.2 - front_t, 1.6]);
                    translate([-0.01, -0.01, -0.01]) cube([W, rad_y - front_t - 0.0, 1.62]);  // keep the gap clear
                }
            for (z = [rad_pos[2] - 1.6, rad_pos[2] + rad_w - 0.6]) translate([wall, rad_y + rad_t + 0.05, z])
                cube([W - 2 * wall, 1.2, 2.2]);                              // rear lips trap the PCB
            for (z = [rad_pos[2] - 1.6, rad_pos[2] + rad_w - 0.6]) translate([wall, rad_y - 0.8, z])
                cube([W - 2 * wall, 0.8, 2.2]);                              // thin front lips at the PCB edges
        }
        // thin the front wall over the light cell (from inside), then the aperture (Ø4.5 mm)
        translate([lux_c[0] - 8.4, lux_wall, lux_c[2] - 6.9]) cube([16.8, front_t, 15]);
        translate([lux_c[0], -0.1, lux_c[2]]) rotate([-90, 0, 0]) cylinder(d = 4.5, h = lux_wall + 0.2);
        // wire hole in the light-cell back wall (sealed with the wires in place)
        translate([lux_c[0], 6.5, lux_c[2] - 4]) rotate([-90, 0, 0]) cylinder(d = 4.5, h = 3);
        // top exhaust vents
        for (i = [0 : 4]) translate([7 + i * 7.2, 11, H - wall - 0.1]) cube([3, D - tb - 14, wall + 0.2]);
        // low side intake slots, both sides
        for (x = [-0.1, W - wall - 0.1]) for (i = [0 : 1]) translate([x, 6 + i * 5, body_z0 + wall + 1.5]) cube([wall + 0.2, 2.5, 7]);
        // USB-C opening, right side
        translate([W - wall - 0.1, usb_c[0] - 3.5, usb_c[1] - 6.25]) cube([wall + 0.2, 7, 12.5]);
        // cable hole to the pod
        translate([cable_x, cable_y, body_z0 - 0.1]) cylinder(d = 4.5, h = wall + 0.2);
    }
}

// Part 3: pod shell (front, sides, roof, floor of the climate pod). Vented on the floor, front and sides.
module pod_shell() {
    difference() {
        cube([W, D - tb - fit, pod_h]);
        translate([wall, wall, wall]) cube([W - 2 * wall, D, pod_h - 2 * wall]);
        for (i = [0 : 5]) translate([5.5 + i * 6.2, 4, -0.1]) cube([3, D - tb - 8, wall + 0.2]);          // floor
        for (i = [0 : 5]) translate([5.5 + i * 6.2, -0.1, 5]) cube([3, wall + 0.2, pod_h - 10]);           // front
        for (x = [-0.1, W - wall - 0.1]) for (i = [0 : 2]) translate([x, 5 + i * 6, 5]) cube([wall + 0.2, 3, pod_h - 10]); // sides
        translate([cable_x, cable_y, pod_h - wall - 0.1]) cylinder(d = 4.5, h = wall + 0.2);            // cable hole
    }
}

// ---------------------------------------------------------------- views
C_BACK = "#7a8a99"; C_BODY = "#e8e4da"; C_POD = "#cfe0e8";

module case_parts() {
    color(C_BACK) back_plate();
    color(C_BODY) body_shell();
    color(C_POD)  pod_shell();
}

module cut_left() { translate([-50, -50, -50]) cube([50 + W / 2, 200, 300]); }   // removes X < W/2
// Removes the front walls (body Y < front_t, pod Y < wall) so the inside shows.
module cut_front() {
    translate([-1, -1, body_z0 - 0.1]) cube([W + 2, front_t + 1.05, body_h + 1]);
    translate([-1, -1, -1]) cube([W + 2, wall + 1.05, pod_h + 1.2]);
}

module note(txt, at, ty, size = 2.3) {
    // Section-view note: text in the cut plane's view, left of the front face, with a leader to `at`.
    x = W / 2 + 0.2;
    color("black") translate([x - 0.3, -8, ty]) rotate([90, 0, -90]) linear_extrude(0.3)
        text(txt, size = size, font = "Liberation Sans:style=Bold", halign = "left", valign = "center");
    wire([[x - 0.3, -7, ty], [x - 0.3, -2, ty], [x - 0.3, at[1], at[2]]], "gray", 0.3);
}

module section_notes() {
    note("Ø4.5 mm lux aperture, sealed light cell", [0, 0.8, lux_c[2]], H - 4);
    note("radar window: 3.8 mm solid PETG", [0, front_t / 2, rad_pos[2] + rad_w + 3], rad_pos[2] + rad_w + 8);
    note("6.2 mm antenna-to-window gap", [0, front_t + radar_gap / 2, rad_pos[2] + rad_w / 2], rad_pos[2] + rad_w / 2);
    note("XIAO ESP32-C3 on the back plate", [0, xiao_pos[1] - 1, xiao_pos[2] + 4], xiao_pos[2] + 2);
    note("10 mm open air gap, 2 pillars only", [0, 12, pod_h + gap_h / 2], pod_h + gap_h / 2);
    note("SHT45 alone in the vented pod", [0, sht_pos[1] - 0.5, sht_pos[2] + sht_w / 2], sht_pos[2] + sht_w / 2 - 2);
}

module labels() {
    label("XIAO ESP32-C3", [xiao_pos[0], xiao_pos[1] - 1.5, xiao_pos[2] + 12]);
    label("LD2412 radar, 5 V + UART", [rad_pos[0], rad_y, rad_pos[2] + 3]);
    label("OPT3001 lux, I2C 0x45", [opt_pos[0], opt_pos[1], lux_c[2] + 3]);
    label("SHT45 T/RH, I2C 0x44", [sht_pos[0], sht_pos[1], sht_pos[2] + 12]);
    label("Wi-Fi antenna (FPC)", [wall + 0.3, 17, body_z0 + 41]);
    label("USB-C 5 V in", [W - wall + 0.5, usb_c[0], usb_c[1]], 1);
    label("STEMMA QT cable", [cable_x, cable_y, pod_h + gap_h / 2], 1);
}

if (view == "assembly" || view == "back") {
    case_parts();
} else if (view == "cutaway") {
    color(C_BACK) back_plate();
    color(C_BODY) difference() { body_shell(); cut_front(); }
    color(C_POD)  difference() { pod_shell(); cut_front(); }
    electronics();
} else if (view == "section") {
    // Vertical cut through the centre (X = W/2), seen from the left: radar gap, light cell, air gap, pod.
    section_notes();
    color(C_BACK) difference() { back_plate(); cut_left(); }
    color(C_BODY) difference() { body_shell(); cut_left(); }
    color(C_POD)  difference() { pod_shell(); cut_left(); }
    difference() { electronics(); cut_left(); }
} else if (view == "exploded") {
    color(C_BACK) back_plate();
    electronics();
    translate([0, -45, 8])  color(C_BODY) body_shell();
    translate([0, -45, -8]) color(C_POD) pod_shell();
} else if (view == "parts") {
    // The three printed parts laid side by side, open sides towards the camera.
    color(C_BACK) back_plate();
    translate([2 * W + 18, D - tb, 0]) rotate([0, 0, 180]) color(C_BODY) body_shell();
    translate([3 * W + 36, D - tb, 0]) rotate([0, 0, 180]) color(C_POD) pod_shell();
} else if (view == "electronics") {
    electronics();
    labels();
    %back_plate();
} else if (view == "part_back_plate") {
    back_plate();
} else if (view == "part_body_shell") {
    body_shell();
} else if (view == "part_pod_shell") {
    pod_shell();
} else if (view == "part_electronics") {
    electronics();
}
