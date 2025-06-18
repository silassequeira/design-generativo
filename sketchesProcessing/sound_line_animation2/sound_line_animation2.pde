import processing.sound.*;

SoundFile song;
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];
color[] cores = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

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
  
  // Initialize line positions
  xPos = new float[numColunas];
  for (int i = 0; i < numColunas; i++) {
    xPos[i] = map(i, 0, numColunas, -100, width);
    lineLengthMods[i] = 0;
    spacingMods[i] = 1.0;
  }
  
  // Initialize sound
  song = new SoundFile(this, "song.mp3");
  fft = new FFT(this, bands);
  fft.input(song);
  
  // Start playback
  song.loop();
  
  // Set text properties
  textSize(16);
  textAlign(LEFT, TOP);
}

void draw() {
  // Dark background
  background(20);
  
  // Analyze sound
  fft.analyze(spectrum);
    
  // Calculate frequency intensities
  float bassIntensity = getBandLevel(20, 150);
  float midIntensity = getBandLevel(151, 1000);
  float trebleIntensity = getBandLevel(1001, 5000);
  float overallIntensity = (bassIntensity + midIntensity + trebleIntensity) / 3.0;
  
  // Update global animation phase
  globalPhase += 0.02 + overallIntensity * 0.05;
  
  // Draw the hypnotic lines with sound reactivity
  drawHypnoticLines(bassIntensity, midIntensity, trebleIntensity);
  
}

float getBandLevel(float lowFreq, float highFreq) {
  // Calculate band indices
  float bandWidth = (song.sampleRate() / 2.0) / bands;
  int lowBin = max(0, min(bands-1, (int)(lowFreq / bandWidth)));
  int highBin = max(0, min(bands-1, (int)(highFreq / bandWidth)));
  
  // Calculate average amplitude in band
  float sum = 0;
  int count = 0;
  for (int i = lowBin; i <= highBin; i++) {
    sum += spectrum[i];
    count++;
  }
  
  if (count > 0) {
    return min(1.0, sum / count * 5); // Scale to make more responsive
  }
  return 0;
}

void drawHypnoticLines(float bass, float mid, float treble) {
  // Base speed with overall intensity modulation
  float speed = 4 + 10 * bass;
  
  for (int i = 0; i < numColunas; i++) {
    float x = xPos[i];
    
    // Calculate center position
    float centerY = height / 2;
    
    // Dynamic spacing with mid frequencies
    float spacing = 30 + 50 * mid + sin(globalPhase + i * 0.2) * 5;
    
    // Dynamic offset with bass modulation
    float offset = (i - numColunas/2.0) * spacing;
    offset += 20 * sin(globalPhase * 2 + i) * bass;
    
    float scaleFactor=0.4;
    float lineY1 = centerY + offset * scaleFactor;
    float lineY2 = centerY - offset * scaleFactor;
    
    // Dynamic line length with treble
    float lengthMod = 1.0 + 2.0 * treble;
    float endX = x + 10 * lengthMod;
    
    // Line weight with frequency modulation
    float lineWeight = 2 + 5 * bass + 5 * abs(sin(radians(frameCount * 2 + i * 10)));
    
    // Get color from palette
    color c = cores[i % cores.length];
    
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


void mousePressed() {
  if (song.isPlaying()) {
    song.pause();
  } else {
    song.play();
  }
}
