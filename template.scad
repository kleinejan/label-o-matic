// Parameters
$fn = 50;
mode = 0; // 0 = STL, 1 = Top View, 2 = Front View, 3 = Perspective View
/*
use <fonts/BrailleCc0-DOeDd.ttf>
use <fonts/AVHersheyComplexHeavy.otf>
use <fonts/AVHersheyComplexMedium.otf>
use <fonts/AVHersheyComplexLight.otf>
*/
$bold = "AVHersheyComplexHeavy";
$medium = "AVHersheyComplexMedium";
$light = "AVHersheyComplexLight";
$braill = "BrailleCc0";



$card_w = {CARD_W};
$card_h = {CARD_H};
$card_thickness = {CARD_THICKNESS};

$hole_size =  {KEY_CHAIN_HOLE};
$key_chain_position = "{KEY_CHAIN_POSITION}";

// Border offset
$card_border_offset =  {BORDEROFFSET};

// Border thickness
$card_border_thickness = {BORDERTHICKNESS};

$radius = {RADIUS};
$bevel = {BEVEL};

$lineheight = {LINEHEIGHT};

// Dynamic text lines
textLines = [
    {TEXT_LINES}
];

// Geometry and text rendering logic remains unchanged

$card_border = $card_border_offset + $card_border_thickness;

$card_w_calculated = $card_w - ($radius * 2);
$card_h_calculated = $card_h - ($radius * 2);


echo("card_w_calculated =", $card_w_calculated);

$card_border_outer_w =  $card_w_calculated - ($card_border_offset * 2);
$card_border_outer_h =  $card_h_calculated - ($card_border_offset * 2);

$card_border_inner_w =  $card_border_outer_w - $card_border_thickness;
$card_border_inner_h = $card_border_outer_h - $card_border_thickness;
//$vpt = [0, 0, $t * 360];
 $vpr = [0, 0, $t * 360];
 $vpd = ($card_w * 3.5);
// Camera Views

module renderView() {
    if (mode == 1) {
        // Top View
            renderCard();

    } else if (mode == 2) {
        // Front View
        rotate([-90,0, 0])
            renderCard();
    } else if (mode == 3) {
        // Perspective View
        rotate([-35, 20, 10])
            renderCard();
    } else {
        // STL Output
        renderCard();
    }
}

// Calculate maximum dimension for scaling the camera
max_dimension = max(card_w, card_h) * 1.2; // Add a 20% buffer to avoid cropping



// Full Card Rendering
module renderCard() {
    union() {
        cardBase();
        cardBorders();
        displayTextLines(textLines);
        if (str($key_chain_position) == "left"){
            $keychain_offset = - $card_w / 2.5;
            keyChain($keychain_offset);
        }else if (str($key_chain_position) == "right"){
            $keychain_offset = - $card_w / 2.5;
            mirror([1,0,0])keyChain($keychain_offset);
         }else if (str($key_chain_position) == "top"){
            $keychain_offset = - $card_h / 2.5;
            mirror([0,1,0])rotate(90)keyChain($keychain_offset);
          }else if (str($key_chain_position) == "bottom"){
            $keychain_offset = - $card_h / 2.5;
            rotate(90)translate([$nw,0,0])keyChain($keychain_offset);
        }else{

        }

    }
}

// Card base
module cardBase() {
    color( "Grey", 1.0 )
    linear_extrude(height = $card_thickness)
    offset(r = $radius)
    square([$card_w_calculated, $card_h_calculated], center = true);
}

module keyChain(offset=0) {
    // Combine 2D shapes using hull()
    color( "Grey", 1.0)
    translate([offset, 0])
    linear_extrude(height = $card_thickness)
     difference() {
        hull() {
            translate([-$card_w/5, 0]) circle(d = $hole_size + 9); // First circle
            circle(d = $card_h / 1.5
            ); // Second circle
        }
     // Create a hole in the smaller circle
                translate([-$card_w / 5, 0]) circle(d = $hole_size); // Hole in the smaller circle
            }
}

// Render the keychain
//mirror([1,0,0])keyChain();
//keyChain();


//border


$bevel_position = $card_thickness - 0.09;



module cardBorders() {
if($card_border_thickness != 0){
color( "Yellow", 1.0)translate([0, 0, $card_thickness - 0.01])difference() {
        linear_extrude(height = $bevel)
        offset(r = $radius)
        square([$card_w_calculated - $card_border_offset, $card_h_calculated - $card_border_offset], center = true);

        linear_extrude(height = $bevel+1)
        offset(r = $radius)
            square([$card_w_calculated - ($card_border_offset + $card_border_thickness), $card_h_calculated - ($card_border_offset + $card_border_thickness)], center = true);

    }
}
}

function add(v, i = 0, r = 0) = i < len(v) ? add(v, i + 1, r + (v[i][1] * $lineheight)) : r;
textblockHeight = add(textLines);


// Function to display text lines with calculated offsets
module displayTextLines(lines, startY = -(textblockHeight / 2), index = 0) {
    // Stop condition for recursion
    if (index < len(lines)) {
        textString = lines[index][0];
        textSize = lines[index][1];
        fontType = lines[index][2];

        // Display text line at the current offset
        translate([0, -startY, $card_thickness - 0.01]) {
            color( "Yellow", 1.0 )
            linear_extrude(height = $bevel)
            text(textString, size = textSize ,font = fontType, halign = "center", valign = "top");
        }

        // Calculate the next offset based on the current text size
        newY = startY + textSize * $lineheight;  // Adjust 1.2 for line spacing

        // Recursively call the module with the next line and updated offset
        displayTextLines(lines, newY, index + 1);
    }
}


renderView();