float hexSize = 40;
float spacingMultiplier = 1.2;

void setup() {
  fullScreen();
  noStroke();
}

void draw() {
  background(0);

  float horizontalSpacing = hexSize * 1.73 * spacingMultiplier;
  float offsetAmount = hexSize * 0.86 * spacingMultiplier;

  // Grid center
  float centerX = width / 2;
  float centerY = height / 2;

  // Build row positions
  ArrayList<Float> rowPositions = new ArrayList<Float>();
  float currentY = -hexSize;
  while (currentY < height + hexSize) {
    rowPositions.add(currentY);
    currentY += hexSize * 1.5 * spacingMultiplier;
  }

  // Draw unified hexagon-square units
  for (int i = 0; i < rowPositions.size(); i++) {
    float y = rowPositions.get(i);
    boolean squaresAtTop = i % 2 == 1;

    for (float x = -hexSize; x < width + hexSize; x += horizontalSpacing) {
      float xOffset = (i % 2 == 0) ? 0 : offsetAmount;
      float worldX = x + xOffset;
      float worldY = y;

      // Calculate distance from center for animation timing
      float distanceFromCenter = dist(worldX, worldY, centerX, centerY);
      float radialTime = map(distanceFromCenter, 0, 800, 0, 2 * TWO_PI);
      float waveProgress = sin(radialTime + frameCount * 0.10);

      if (waveProgress > 0) {
        drawUnit(worldX, worldY, hexSize, i, x, waveProgress);
      }
    }
  }
}

// Unified hexagon-square unit with dynamic motion
void drawUnit(float cx, float cy, float s, int row, float col, float waveProgress) {
  pushMatrix();
  translate(cx, cy);

  // Orbit motion
  float orbitAngle = (cx * 0.001 + cy * 0.001 + frameCount * 0.01);
  float orbitRadius = 5 * waveProgress;
  float orbitX = cos(orbitAngle) * orbitRadius;
  float orbitY = sin(orbitAngle) * orbitRadius;

  translate(orbitX, orbitY);

  // Opacity pulsing
  // Draw hexagon
  fill(213, 90, 36);
  hexShape(s);

  fill(0);
  hexShape(s * 0.7);

  fill(154, 19, 29);
  hexShape(s * 0.4);

  // Draw square
  float squareOffset = (row % 2 == 1) ? -1 : 1;
  pushMatrix();
  translate(0, hexSize * 0.7 * squareOffset);
  scale(1, 1.2);
  fill(0);
  squareShape();
  popMatrix();

  popMatrix();
}

// Shape drawing functions
void hexShape(float r) {
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i + PI / 6;
    float x = cos(angle) * r;
    float y = sin(angle) * r;
    vertex(x, y);
  }
  endShape(CLOSE);
}

void squareShape() {
  rect(-hexSize/6, -hexSize/4, hexSize/3, hexSize/2);
}
