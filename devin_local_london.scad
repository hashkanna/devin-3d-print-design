// Devin Local: London — spinning London Eye keychain
//
// The London skyline from the event poster, with a London Eye that spins.
// The wheel is print-in-place: a V-shaped bearing edge captures it inside
// its frame, so it comes off the bed already assembled. No supports.
//
// Render one part from the command line:
//   openscad -D 'part="all"' -o keychain.stl devin_local_london.scad

/* [Output] */
// Which part to render
part = "all"; // [all, base, accent, eye_test, preview, cutaway]
// Print-in-place spinning wheel (false = solid keychain, no moving parts)
spinner = true;

/* [Label] */
label = "DEVIN LOCAL";
font = "Liberation Sans:style=Bold";
text_size = 6.2;
text_spacing = 1.05;

/* [Print tuning] */
// Clearance between wheel and frame, measured normal to the surface (mm)
gap = 0.45;
// Body thickness (mm)
base_t = 4;
// Height of raised details; swap filament at this layer for two colours (mm)
accent_t = 0.8;
// Depth of engraved line details (mm)
engrave_d = 0.8;

/* [Hidden] */
$fn = 96;
eps = 0.01;

band = [75, 12];
band_r = 3.5;
b = band[1];                    // skyline ground line
ring_hole_d = 4.8;
ring_hole_c = [5, band[1] / 2];

// London Eye
eye_r = 11;                     // wheel radius at the root of the bearing edge
bearing = 1.3;                  // how far the V edge sticks out
frame_w = 1.8;                  // thinnest frame wall
rim_w = 2.4;
hub_r = 3.2;
spokes = 16;
spoke_w = 0.9;
pods = 16;                      // hexagonal capsules
pod_r = 0.95;
eye_R = eye_r + bearing + gap + frame_w;
eye_c = [band[0] - eye_R, b + eye_R - 1.5];

// ---------------------------------------------------------------- helpers

module rounded_rect(size, r) {
    offset(r) offset(-r) square(size);
}

module arch(w, h) {
    translate([-w / 2, 0]) square([w, h - w / 2]);
    translate([0, h - w / 2]) circle(d = w, $fn = 32);
}

module hexagon(r) {
    rotate(30) circle(r = r, $fn = 6);
}

// ---------------------------------------------------------------- skyline

module tower_bridge(x) {
    module tower(x) translate([x, 0]) difference() {
        union() {
            translate([0, b - 1]) square([5, 12.5]);
            polygon([[0, b + 11.5], [5, b + 11.5], [2.5, b + 15]]);
            for (px = [0, 3.9]) translate([px, b + 10.5]) {
                square([1.1, 2.6]);
                polygon([[0, 2.6], [1.1, 2.6], [0.55, 4.2]]);
            }
        }
        translate([2.5, b - 1]) arch(2.2, 5);
        translate([2.5, b + 6.5]) arch(1.3, 2.8);
    }
    tower(x);
    tower(x + 9.5);
    // high-level walkways
    translate([x + 5 - eps, b + 8.6]) square([4.5 + 2 * eps, 1.3]);
}

module shard(x) translate([x, 0]) polygon([
    [0, b - 0.5], [9, b - 0.5],
    [5.3, b + 25.5], [5.6, b + 28.4],
    [4.75, b + 26.6], [4.25, b + 29.4],
    [3.7, b + 26]
]);

function gherkin_w(t) = t < 0.3
    ? 0.8 + 0.2 * sin(90 * t / 0.3)
    : sqrt(1 - pow((t - 0.3) / 0.7, 2));

module gherkin(x, w = 7, h = 18) translate([x + w / 2, b - 0.5]) {
    n = 30;
    right = [for (i = [0 : n - 1]) [gherkin_w(i / n) * w / 2, i * h / n]];
    left = [for (i = [n - 1 : -1 : 0]) [-right[i][0], right[i][1]]];
    polygon(concat(right, [[0, h]], left));
}

module big_ben(x) translate([x, 0]) {
    translate([0.75, b - 1]) square([4.5, 18]);
    translate([0, b + 16]) square([6, 6]);                       // clock stage
    translate([0.5, b + 22 - eps]) square([5, 2]);               // belfry
    polygon([[0.2, b + 23.8], [5.8, b + 23.8], [3, b + 28.6]]);  // roof
    polygon([[2.55, b + 28], [3.45, b + 28], [3, b + 31]]);      // spire
}

tb_x = 1.5;
shard_x = 18.2;
gherkin_x = 28.4;
ben_x = 37;
ben_clock = [ben_x + 3, b + 19];

module skyline() {
    tower_bridge(tb_x);
    shard(shard_x);
    gherkin(gherkin_x);
    big_ben(ben_x);
}

module outline() {
    difference() {
        union() {
            rounded_rect(band, band_r);
            skyline();
            translate(eye_c) circle(eye_R, $fn = 180);
        }
        translate(ring_hole_c) circle(d = ring_hole_d, $fn = 48);
    }
}

// Line details cut into the top face.
module engravings() {
    // the Shard's facet
    translate([shard_x, 0]) polygon([
        [4.2, b + 1], [5.0, b + 1], [4.85, b + 24], [4.55, b + 24]
    ]);
    // the Gherkin's spiral bands
    intersection() {
        offset(-0.9) gherkin(gherkin_x);
        for (i = [-4 : 4])
            translate([gherkin_x + 3.5, b + 8 + i * 2.6]) rotate(28)
                square([16, 0.8], center = true);
    }
    // Big Ben's shaft windows
    for (dx = [1.9, 3.4]) translate([ben_x + dx, b + 2]) square([0.7, 12.5]);
    // the band's border line
    difference() {
        offset(-1.2) rounded_rect(band, band_r);
        offset(-1.9) rounded_rect(band, band_r);
        translate(ring_hole_c) circle(d = ring_hole_d + 3);
        translate(eye_c) circle(eye_R + 0.5);
    }
}

// ---------------------------------------------------------------- the Eye

// Cross-section (r, z) of the wheel's bearing edge.
module wheel_profile() {
    polygon([
        [eye_r - rim_w, 0], [eye_r, 0],
        [eye_r + bearing, bearing], [eye_r + bearing, base_t - bearing],
        [eye_r, base_t], [eye_r - rim_w, base_t]
    ]);
}

// Cavity in the frame: the wheel profile grown by `c` normal to every face.
// A negative `c` overlaps the wheel instead, fusing it (the static build).
module cavity_profile(c) {
    d = c * sqrt(2);
    polygon([
        [0, -1], [eye_r + d - 1, -1],
        [eye_r + bearing + c, bearing + c - d],
        [eye_r + bearing + c, base_t - bearing - c + d],
        [eye_r + d - 1, base_t + 1], [0, base_t + 1]
    ]);
}

module wheel() translate(eye_c) {
    rotate_extrude($fn = 180) wheel_profile();
    linear_extrude(base_t) {
        hexagon(hub_r);
        for (i = [0 : spokes - 1]) rotate(i * 360 / spokes)
            translate([0, -spoke_w / 2]) square([eye_r - rim_w + eps, spoke_w]);
    }
}

module eye_cavity() {
    translate(eye_c) rotate_extrude($fn = 180) cavity_profile(spinner ? gap : -0.2);
}

// ---------------------------------------------------------------- parts

module base() {
    difference() {
        linear_extrude(base_t) outline();
        eye_cavity();
        translate([0, 0, base_t - engrave_d]) linear_extrude(engrave_d + 1) engravings();
    }
    wheel();
}

module accent() {
    translate([0, 0, base_t - eps]) linear_extrude(accent_t + eps) {
        translate([(ring_hole_c[0] + ring_hole_d / 2 + band[0] + 0.5) / 2 - 0.5, band[1] / 2])
            text(label, size = text_size, font = font, spacing = text_spacing,
                 halign = "center", valign = "center");
        // Big Ben's clock face
        translate(ben_clock) difference() {
            circle(r = 2.1, $fn = 48);
            circle(r = 1.35, $fn = 48);
        }
        translate(ben_clock) {
            rotate(90) translate([0, -0.3]) square([1.3, 0.6]);
            rotate(-30) translate([0, -0.3]) square([1.0, 0.6]);
        }
        // hub nut and hexagonal capsules on the wheel
        translate(eye_c) {
            difference() {
                hexagon(2.4);
                hexagon(1.1);
            }
            for (i = [0 : pods - 1]) rotate(i * 360 / pods + 180 / pods)
                translate([eye_r - rim_w / 2, 0]) hexagon(pod_r);
        }
    }
}

// Just the Eye, to dial in `gap` on your printer before the full print.
module eye_test() {
    translate(-eye_c) {
        difference() {
            translate(eye_c) cylinder(r = eye_R, h = base_t, $fn = 180);
            eye_cavity();
        }
        wheel();
    }
}

// Back half of whatever is passed in, cut through the Eye's centre.
module back_half(c) color(c) intersection() {
    children();
    translate([eye_c[0] - 50, eye_c[1] - 0.2, -1]) cube([100, 50, 10]);
}

if (part == "all") {
    base();
    accent();
} else if (part == "base") {
    base();
} else if (part == "accent") {
    accent();
} else if (part == "eye_test") {
    eye_test();
} else if (part == "preview") {
    color("#2b2f36") base();
    color("#f39a2b") accent();
} else if (part == "cutaway") {
    // The Eye sliced through its centre, to show the bearing
    translate(-eye_c) {
        back_half("#2b2f36") difference() {
            translate(eye_c) cylinder(r = eye_R, h = base_t, $fn = 180);
            eye_cavity();
        }
        back_half("#f39a2b") wheel();
    }
}
