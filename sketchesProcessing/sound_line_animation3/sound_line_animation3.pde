import processing.sound.*;

SoundFile song;
FFT fft;

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
  color(229, 0, 0), color(204, 0, 0), color(178, 0, 0), 
  color(153, 0, 0), color(127, 0, 0), color(102, 0, 0)
};

color[] greenPalette = {
  color(0, 229, 0), color(0, 204, 0), color(0, 178, 0), 
  color(0, 153, 0), color(0, 127, 0), color(0, 102, 0)
};

color[] orangePalette = {
  color(255, 165, 0), color(230, 149, 0), color(205, 133, 0), 
  color(180, 118, 0), color(155, 102, 0), color(130, 87, 0)
};

color[] bluePalette = {
  color(0, 153, 255), color(0, 122, 204), color(0, 92, 163), 
  color(0, 61, 122), color(0, 31, 82), color(0, 0, 41)
};

// Store all palettes in an array for easy switching
color[][] allPalettes = {mainColors, redPalette, greenPalette, orangePalette, bluePalette};
int activePaletteIndex = 0; // Start with main colors

float[] lastEnergies;
float[] currentEnergies;

int numLines = 30; // Number of lines to draw
float[] angles;    // Direction of each line

void setup() {
  fullScreen();
  background(0);
  frameRate(60);

  // Load the MP3 file
  song = new SoundFile(this, "song.mp3");
  song.loop();

  // Initialize FFT
  fft = new FFT(this);
  fft.input(song);

  // Initialize arrays based on active palette
  updateEnergyArrays();

  // Set initial angles for lines
  angles = new float[numLines];
  for (int i = 0; i < numLines; i++) {
    angles[i] = map(i, 0, numLines, 0, TWO_PI);
  }
}

void updateEnergyArrays() {
  // Get current active palette
  color[] activeColors = allPalettes[activePaletteIndex];
  
  // Initialize or resize energy arrays if needed
  if (lastEnergies == null || lastEnergies.length != activeColors.length) {
    lastEnergies = new float[activeColors.length];
    currentEnergies = new float[activeColors.length];
  }
}

void draw() {
  background(0, 20); // Fade effect

  // Perform FFT analysis
  fft.analyze();

  // Get current active palette
  color[] activeColors = allPalettes[activePaletteIndex];
  
  // Update energy values for each color
  for (int i = 0; i < activeColors.length; i++) {
    float freqBand = map(i, 0, activeColors.length - 1, 0, fft.spectrum.length - 1);
    int index = (int) freqBand;

    if (index >= 0 && index < fft.spectrum.length) {
      float energy = abs(fft.spectrum[index]) * 20;

      lastEnergies[i] = currentEnergies[i];
      currentEnergies[i] = energy;
    }
  }

  translate(width / 2, height / 2); // Center origin
  scale(2, 2);

  // Draw audio-reactive lines
  for (int i = 0; i < numLines; i++) {
    // Get color based on line index
    int colorIndex = int(map(i, 0, numLines, 0, activeColors.length - 1));
    color baseColor = activeColors[colorIndex % activeColors.length];
    color nextColor = activeColors[(colorIndex + 1) % activeColors.length];

    // Interpolate colors
    stroke(lerpColor(baseColor, nextColor, abs(sin(millis() * 0.001))));
    strokeWeight(2);

    // Calculate line length based on energy and time
    float energy = lerp(lastEnergies[colorIndex % activeColors.length], 
                         currentEnergies[colorIndex % activeColors.length], 0.1);
    float baseLength = map(energy, 0, 200, 30, 300);
    float dynamicLength = 3 * baseLength * (1 + 0.5 * sin(millis() * 0.002 + i));

    // Add oscillation to angle
    float angle = angles[i] + 0.05 * sin(millis() * 0.001 + i);

    // Calculate start and end points
    float x1 = 0;
    float y1 = 0;
    float x2 = cos(angle) * dynamicLength;
    float y2 = sin(angle) * dynamicLength;

    // Draw the line
    line(x1, y1, x2, y2);

    // Update angle for motion
    angles[i] += 0.002;

    // Add particles at line ends
    if (energy > 120) {
      drawParticle(x2, y2, baseColor);
    }
  }
  
  // Reset transform before drawing UI
  resetMatrix();
  
  // Display current palette name
  fill(255);
  textSize(16);
  String paletteName = getPaletteName(activePaletteIndex);
  text("Current Palette: " + paletteName, 20, 30);
  text("Press 1-5 keys to change palette", 20, 60);
}

String getPaletteName(int index) {
  String[] names = {"Main Colors", "Red", "Green", "Orange", "Blue"};
  return names[index];
}

void drawParticle(float x, float y, color c) {
  fill(c, 150);
  noStroke();
  ellipse(x, y, 8, 8);
  for (int i = 1; i < 4; i++) {
    ellipse(x + random(-i * 2, i * 2), y + random(-i * 2, i * 2), 15 - i * 3, 15 - i * 3);
  }
}

void keyPressed() {
  // Use number keys 1-5 to select specific palettes
  if (key >= '1' && key <= '5') {
    int selectedIndex = key - '1'; // Convert key to index (0-4)
    if (selectedIndex < allPalettes.length) {
      activePaletteIndex = selectedIndex;
      updateEnergyArrays(); // Update arrays for the new palette
    }
  } else if (key == ' ') {
    // Toggle play/pause with spacebar
    if (song.isPlaying()) {
      song.pause();
    } else {
      song.play();
    }
  }
}

void stop() {
  song.stop();
  super.stop();
}
