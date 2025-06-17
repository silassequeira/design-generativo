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

int numLines = 120;  // Increased for smoother wave effect
float[] linePositions;
float[] lineLengths;
float[] waveAmplitudes;
float globalWavePhase = 0;
float globalWaveSpeed = 0.02;

void setup() {
  size(1200, 800);
  smooth();
  frameRate(60);
  strokeCap(ROUND);
  
  // Initialize line properties
  linePositions = new float[numLines];
  lineLengths = new float[numLines];
  waveAmplitudes = new float[numLines];
  
  // Position lines evenly across the screen
  for (int i = 0; i < numLines; i++) {
    linePositions[i] = map(i, 0, numLines, -width/2, width * 1.5);
    lineLengths[i] = 0;
    waveAmplitudes[i] = random(50, 150);
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
  
  // Update global wave phase
  globalWavePhase += globalWaveSpeed + overallIntensity * 0.05;
  
  // Draw animated lines with sound reactivity
  drawWaveLines(bassIntensity, midIntensity, trebleIntensity, overallIntensity);
  
  // Draw visualizer UI
  drawVisualizer(bassIntensity, midIntensity, trebleIntensity);
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

void drawWaveLines(float bass, float mid, float treble, float overall) {
  // Base wave parameters
  float waveSpeed = 0.05 + overall * 0.1;
  float waveHeight = 100 + bass * 300;
  float lineBaseLength = 20 + treble * 300;
  
  // Center position with vertical movement based on bass
  float centerY = height/2 + sin(millis() * 0.001) * bass * 100;
  
  for (int i = 0; i < numLines; i++) {
    // Calculate wave position
    float wavePhase = globalWavePhase + i * 0.1;
    
    // Calculate y positions with wave effect
    float waveOffset = sin(wavePhase) * waveHeight * (1 + mid * 0.5);
    float y1 = centerY - waveOffset;
    float y2 = centerY + waveOffset;
    
    // Dynamic line length
    float length = lineBaseLength * (1 + sin(wavePhase * 2) * 0.3);
    
    // Get color from palette
    color c = cores[i % cores.length];
    
    // Color modulation based on frequencies
    float r = red(c) * (1 + bass * 0.5);
    float g = green(c) * (1 + mid * 0.5);
    float b = blue(c) * (1 + treble * 0.5);
    
    stroke(
      min(255, r),
      min(255, g),
      min(255, b),
      200
    );
    
    // Line weight based on position and intensity
    float weight = 2 + 20 * (abs(sin(wavePhase)) * (1 + overall * 2));
    strokeWeight(weight);
    
    // Draw the line
    float x = linePositions[i];
    line(x, y1, x, y2);
    
    // Draw connecting wave effect between lines
    if (i > 0) {
      float prevX = linePositions[i-1];
      float prevY1 = centerY - sin(globalWavePhase + (i-1)*0.1) * waveHeight * (1 + mid * 0.5);
      
      stroke(200, 200, 255, 50);
      strokeWeight(1);
      line(prevX, prevY1, x, y1);
      line(prevX, prevY1 + waveOffset * 2, x, y2);
    }
    
    // Update position
    linePositions[i] += 2 + bass * 10;
    if (linePositions[i] > width * 1.5) {
      linePositions[i] = -width/2;
      waveAmplitudes[i] = 50 + random(100) + bass * 200;
    }
  }
}

void drawVisualizer(float bass, float mid, float treble) {
  pushStyle();
  noStroke();
  
  // Draw title
  fill(240);
  textSize(24);
  text("Generative Sound Wave Visualization", 20, 20);
  textSize(16);
  text("Bass: " + nf(bass, 0, 2), 20, 60);
  text("Mid: " + nf(mid, 0, 2), 20, 90);
  text("Treble: " + nf(treble, 0, 2), 20, 120);
  
  // Draw frequency bars
  float barWidth = width / bands;
  for (int i = 0; i < bands; i++) {
    float h = spectrum[i] * height * 2;
    if (h > 0) {
      // Color based on frequency band
      if (i < bands/3) {
        fill(200, 50, 50, 200); // Bass - red
      } else if (i < bands*2/3) {
        fill(50, 200, 50, 200); // Mid - green
      } else {
        fill(50, 100, 200, 200); // Treble - blue
      }
      
      rect(i * barWidth, height - h, barWidth, h);
    }
  }
  
  // Draw play/pause status
  if (song.isPlaying()) {
    fill(100, 200, 100);
    text("PLAYING - Click to pause", 20, height - 40);
  } else {
    fill(200, 100, 100);
    text("PAUSED - Click to play", 20, height - 40);
  }
  
  popStyle();
}

void mousePressed() {
  if (song.isPlaying()) {
    song.pause();
  } else {
    song.play();
  }
}
