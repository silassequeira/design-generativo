// Main colors and specialized palettes
color[] mainColors = {
  color(35, 139, 47),    // Green 
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

color[] redPalette = {
  color(229, 0, 0),      // Vibrant red
  color(204, 0, 0),      // Classic red
  color(178, 0, 0),      // Deeper red
  color(153, 0, 0),      // Rich red
  color(127, 0, 0),      // Burgundy red
  color(102, 0, 0)       // Dark maroon
};

color[] greenPalette = {
  color(0, 229, 0),      // Lime green
  color(0, 204, 0),      // Bright green
  color(0, 178, 0),      // Natural green
  color(0, 153, 0),      // Forest green
  color(0, 127, 0),      // Dark green
  color(0, 102, 0)       // Hunter green
};

color[] orangePalette = {
  color(255, 165, 0),    // Vibrant orange
  color(230, 149, 0),    // Traditional orange
  color(205, 133, 0),    // Muted orange
  color(180, 118, 0),    // Burnt orange
  color(155, 102, 0),    // Earthy orange
  color(130, 87, 0)      // Brownish-orange
};

color[] bluePalette = {
  color(0, 153, 255),    // Vibrant blue
  color(0, 122, 204),    // Medium blue
  color(0, 92, 163),     // Traditional blue
  color(0, 61, 122),     // Darker blue
  color(0, 31, 82),      // Navy blue
  color(0, 0, 41)        // Black-blue
};

// Store all palettes in an array for easy switching
color[][] allPalettes = {mainColors, redPalette, greenPalette, orangePalette, bluePalette};
int activePaletteIndex = 0; // Start with main colors

PFont font;
float time = 0;
int blinkingIndex = 0;
int blinkTimer = 0;
int paletteChangeTimer = 0;

void setup() {
  fullScreen();
  font = createFont("Courier", 60, true);
  textFont(font);
  textAlign(CENTER, CENTER);
  frameRate(30);
}

void draw() {
  background(0);
  time += 0.03;
  blinkTimer++;
  paletteChangeTimer++;
  
  // Change blinking word every 2 seconds
  if (blinkTimer > 60) {
    blinkingIndex = (blinkingIndex + 1) % 3;
    blinkTimer = 0;
  }
  
  // Change color palette every 5 seconds
  if (paletteChangeTimer > 150) {
    activePaletteIndex = (activePaletteIndex + 1) % allPalettes.length;
    paletteChangeTimer = 0;
  }

  // Get the current active palette
  color[] currentPalette = allPalettes[activePaletteIndex];

  for (int i = 0; i < 3; i++) {
    float x = width / 4.0 * (i + 1);
    float y = height / 2.0;
    boolean isBlinking = (i == blinkingIndex);
    
    // All words use the same palette
    drawVerticalWord("REDRUM", x, y, isBlinking, currentPalette);
  }
}

void drawVerticalWord(String word, float x, float centerY, boolean blink, color[] palette) {
  float spacing = 60;
  float totalHeight = word.length() * spacing;
  float startY = centerY - totalHeight / 2;
  
  for (int i = 0; i < word.length(); i++) {
    float y = startY + i * spacing;

    if (blink) {
      // Blinking effect
      if (frameCount % 20 < 10) {
        color letterColor = palette[int(random(palette.length))];
        fill(letterColor);
        text(word.charAt(i), x + random(-1, 1), y + random(-1, 1));
      }
    } else {
      // For non-blinking words
      color letterColor = palette[int(random(palette.length))];
      fill(letterColor);
      text(word.charAt(i), x + random(-1, 1), y + random(-1, 1));
    }
  }
}

// Add keyboard control to manually change palettes
void keyPressed() {
  if (key == ' ') {
    activePaletteIndex = (activePaletteIndex + 1) % allPalettes.length;
    paletteChangeTimer = 0;
  }
}
