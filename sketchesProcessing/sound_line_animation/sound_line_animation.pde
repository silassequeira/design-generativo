import processing.sound.*;

SoundFile song;
Amplitude analyzer;

color[] cores = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

float lineSpacing = 40;
float scroll = 0;
float amplitude = 0;
float smoothAmplitude = 0;
float maxAmplitude = 0.01;
float bassLevel = 0;
float midLevel = 0;
float trebleLevel = 0;

void setup() {
  size(1000, 600);
  frameRate(60);
  rectMode(CENTER);
  
  // Initialize sound
  song = new SoundFile(this, "song.mp3");
  analyzer = new Amplitude(this);
  
  // Analyze the entire sound file
  analyzer.input(song);
  
  // Start playback
  song.play();
  song.loop();
  
  // Create UI elements
  createControls();
}

void draw() {
  background(20);
  
  // Update amplitude analysis
  amplitude = analyzer.analyze();
  smoothAmplitude = lerp(smoothAmplitude, amplitude, 0.2);
  
  // Update max amplitude for scaling
  if (amplitude > maxAmplitude) {
    maxAmplitude = amplitude;
  }
  
  // Analyze frequency bands (simulated)
  bassLevel = getBandLevel(0, 100);
  midLevel = getBandLevel(100, 1000);
  trebleLevel = getBandLevel(1000, 5000);
  
  // Draw the animated road
  drawRoad();
  
  // Draw visualization and UI
  drawVisualization();
  drawUI();
  
  // Update scroll position
  scroll += 2 + 20 * bassLevel;
}

void drawRoad() {
  for (int i = 0; i < height / lineSpacing + 2; i++) {
    float y = (i * lineSpacing - scroll % lineSpacing);
    
    // Base properties
    float baseWidth = width * 0.8;
    float baseHeight = 10;
    
    // Dynamic effects based on sound
    float pulse = 1.0 + 1.5 * smoothAmplitude * sin(frameCount * 0.05 + i * 0.3);
    float heightMod = baseHeight * pulse;
    float widthMod = baseWidth * (1.0 + 0.3 * midLevel);
    
    // Color effects
    color c = cores[i % cores.length];
    float colorMod = 1.0 + 0.5 * trebleLevel;
    fill(
      min(255, red(c) * colorMod),
      min(255, green(c) * colorMod),
      min(255, blue(c) * colorMod)
    );
    
    // Position modulation
    float xMod = width/2 + (width * 0.05 * sin(frameCount * 0.1 + i * 0.2) * bassLevel);
    
    rect(xMod, y, widthMod, heightMod);
  }
}

// Simulated frequency band analysis
float getBandLevel(float low, float high) {
  // This is a simplified simulation - in a real application you would use FFT
  float time = (frameCount % 100) / 100.0;
  float freq = map(song.position(), 0, song.duration(), low, high);
  float level = abs(sin(time * TWO_PI + freq * 0.001)) * smoothAmplitude;
  return constrain(level, 0, 1);
}

void drawVisualization() {
  pushMatrix();
  translate(width - 200, 20);
  
  // Draw amplitude meter
  fill(50);
  rect(0, 0, 40, 200);
  float ampHeight = map(smoothAmplitude, 0, maxAmplitude, 0, 200);
  fill(100, 200, 100);
  rect(0, 200, 40, -ampHeight);
  
  // Draw frequency bands
  translate(60, 0);
  fill(200, 100, 100);
  rect(0, 200, 40, -bassLevel * 200);
  fill(200, 200, 100);
  rect(40, 200, 40, -midLevel * 200);
  fill(100, 100, 200);
  rect(80, 200, 40, -trebleLevel * 200);
  
  // Draw labels
  fill(240);
  textSize(12);
  textAlign(CENTER);
  text("AMP", 20, 220);
  text("BASS", 20, 240);
  text("MID", 60, 240);
  text("TREBLE", 100, 240);
  
  popMatrix();
}

void drawUI() {
  fill(240);
  textSize(16);
  textAlign(LEFT);
  text("Music-Reactive Road Animation", 20, 30);
  textSize(14);
  text("Amplitude: " + nf(smoothAmplitude, 0, 3), 20, 50);
  text("Bass: " + nf(bassLevel, 0, 2), 20, 70);
  text("Mid: " + nf(midLevel, 0, 2), 20, 90);
  text("Treble: " + nf(trebleLevel, 0, 2), 20, 110);
  
  // Draw play/pause button
  fill(100);
  rect(20, 140, 60, 30, 5);
  fill(240);
  if (song.isPlaying()) {
    text("Pause", 20, 145);
  } else {
    text("Play", 20, 145);
  }
}

void createControls() {
  // This would normally create control elements
  // In Processing, we typically draw UI directly in draw()
}

void mousePressed() {
  // Toggle play/pause when button is clicked
  if (mouseX > 20 && mouseX < 80 && mouseY > 125 && mouseY < 155) {
    if (song.isPlaying()) {
      song.pause();
    } else {
      song.play();
    }
  }
}
