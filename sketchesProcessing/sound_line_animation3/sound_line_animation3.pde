import processing.sound.*;

SoundFile song;
FFT fft;

color[] colors = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

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

  // Initialize arrays
  lastEnergies = new float[colors.length];
  currentEnergies = new float[colors.length];
  angles = new float[numLines];

  // Set initial angles for lines
  for (int i = 0; i < numLines; i++) {
    angles[i] = map(i, 0, numLines, 0, TWO_PI);
  }
}

void draw() {
  background(0, 20); // Fade effect

  // Perform FFT analysis
  fft.analyze();

  // Update energy values for each color
  for (int i = 0; i < colors.length; i++) {
    float freqBand = map(i, 0, colors.length - 1, 0, fft.spectrum.length - 1);
    int index = (int) freqBand;

    if (index >= 0 && index < fft.spectrum.length) {
      float energy = abs(fft.spectrum[index]) * 20;

      lastEnergies[i] = currentEnergies[i];
      currentEnergies[i] = energy;
    }
  }

  translate(width / 2, height / 2); // Center origin
  scale(2,2);

  // Draw audio-reactive lines
  for (int i = 0; i < numLines; i++) {
    // Get color based on line index
    int colorIndex = int(map(i, 0, numLines, 0, colors.length - 1));
    color baseColor = colors[colorIndex];
    color nextColor = colors[(colorIndex + 1) % colors.length];

    // Interpolate colors
    stroke(lerpColor(baseColor, nextColor, abs(sin(millis() * 0.001))));
    strokeWeight(2);

    // Calculate line length based on energy and time
    float energy = lerp(lastEnergies[colorIndex], currentEnergies[colorIndex], 0.1);
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
      drawParticle(x2 + width / 2, y2 + height / 2, baseColor);
    }
  }
}

void drawParticle(float x, float y, color c) {
  fill(c, 150);
  noStroke();
  ellipse(x, y, 8, 8);
  for (int i = 1; i < 4; i++) {
    ellipse(x + random(-i * 2, i * 2), y + random(-i * 2, i * 2), 15 - i * 3, 15 - i * 3);
  }
}

void stop() {
  song.stop();
  super.stop();
}
