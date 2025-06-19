import processing.sound.*;

SoundFile song;
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

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
  color(35, 139, 47),    // Green 
  color(0, 204, 0),      // Bright green
  color(0, 178, 0),      // Natural green
  color(0, 153, 0),      // Forest green
  color(0, 127, 0),      // Dark green
  color(0, 102, 0),       // Hunter green
    color(226, 190, 82),   // Yellow
  color(247, 236, 205)  // Yellow Light
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

color[][] allPalettes = {mainColors, redPalette, greenPalette, orangePalette, bluePalette};
int activePaletteIndex = 0; 

int numColunas = 40;
float[] xPos;
float[] lineLengthMods = new float[numColunas];
float[] spacingMods = new float[numColunas];
float globalPhase = 0;

void setup() {
  fullScreen();
  smooth();
  frameRate(60);
  strokeCap(ROUND);
  
  xPos = new float[numColunas];
  for (int i = 0; i < numColunas; i++) {
    xPos[i] = map(i, 0, numColunas, -100, width);
    lineLengthMods[i] = 0;
    spacingMods[i] = 1.0;
  }
  
  song = new SoundFile(this, "Main Title.mp3");
  fft = new FFT(this, bands);
  fft.input(song);
  
  song.loop();
  
  textSize(16);
  textAlign(LEFT, TOP);
}

void draw() {
  background(20);
  
    fft.analyze(spectrum);
    
  // Calculate frequency intensities
  float bassIntensity = getBandLevel(20, 150);
  float midIntensity = getBandLevel(151, 1000);
  float trebleIntensity = getBandLevel(1001, 5000);
  float overallIntensity = (bassIntensity + midIntensity + trebleIntensity) / 3.0;
  
  // Update global animation phase
  globalPhase += 0.02 + overallIntensity * 0.05;
  
  drawHypnoticLines(bassIntensity, midIntensity, trebleIntensity);
  
}

String getPaletteName(int index) {
  String[] names = {"Main Colors", "Red Palette", "Green Palette", "Orange Palette", "Blue Palette"};
  return names[index];
}

float getBandLevel(float lowFreq, float highFreq) {
  // Calculate band indices
  float bandWidth = (song.sampleRate() / 2.0) / bands;
  int lowBin = max(0, min(bands-1, (int)(lowFreq / bandWidth)));
  int highBin = max(0, min(bands-1, (int)(highFreq / bandWidth)));
  
  float sum = 0;
  int count = 0;
  for (int i = lowBin; i <= highBin; i++) {
    sum += spectrum[i];
    count++;
  }
  
  if (count > 0) {
    return min(1.0, sum / count * 5);
  }
  return 0;
}

void drawHypnoticLines(float bass, float mid, float treble) {
  color[] currentPalette = allPalettes[activePaletteIndex];
  
  float speed = 4 + 10 * bass;
  
  for (int i = 0; i < numColunas; i++) {
    float x = xPos[i];
    
    float centerY = height / 2;
    
    // Dynamic spacing with mid frequencies
    float spacing = 30 + 50 * mid + sin(globalPhase + i * 0.2) * 5;
    
    // Dynamic offset with bass modulation
    float offset = (i - numColunas/2.0) * spacing;
    offset += 20 * sin(globalPhase * 2 + i) * bass;
    
    float scaleFactor = 0.4;
    float lineY1 = centerY + offset * scaleFactor;
    float lineY2 = centerY - offset * scaleFactor;
    
    // Dynamic line length with treble
    float lengthMod = 1.0 + 2.0 * treble;
    float endX = x + 10 * lengthMod;
    
    // Line weight with frequency modulation
    float lineWeight = 2 + 5 * bass + 5 * abs(sin(radians(frameCount * 2 + i * 10)));
    
    // Get color from current palette (cycling through the colors)
    color c = currentPalette[i % currentPalette.length];
    
    // Subtle color modulation based on frequencies
    float r = min(255, red(c) * (1 + bass * 0.2));
    float g = min(255, green(c) * (1 + mid * 0.2));
    float b = min(255, blue(c) * (1 + treble * 0.2));
    
    stroke(r, g, b);
    strokeWeight(lineWeight);
    
    // Draw the hypnotic line
    line(x, lineY1, endX, lineY2);
    
    // Update position
    xPos[i] += speed;
    if (xPos[i] > width + 50) {
      xPos[i] = -50;
      
      // Add subtle variation when lines reset
      spacingMods[i] = 0.8 + random(0.4);
    }
  }
}

  // Use number keys 1-5 to select specific palettes
void keyPressed() {
  if (key >= '1' && key <= '5') {
    int selectedIndex = key - '1';
    if (selectedIndex < allPalettes.length) {
      activePaletteIndex = selectedIndex;
    }
  }
}
