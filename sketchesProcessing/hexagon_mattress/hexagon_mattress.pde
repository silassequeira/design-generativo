float hexSize = 50;
float spacingMultiplier = 1.2;
int globalCounter = 0;

void setup() {
  fullScreen();
  noStroke();
}

void draw() {
  background(0);

  float horizontalSpacing = hexSize * 1.73 * spacingMultiplier;
  float offsetAmount = hexSize * 0.86 * spacingMultiplier;

  ArrayList<Float> rowPositions = new ArrayList<Float>();
  float currentY = -hexSize;
  int rowCount = 0;

  while (currentY < height + hexSize) {
    rowPositions.add(currentY);

    if (rowCount % 2 == 0) {
      currentY += hexSize * 1.5 - 15 * spacingMultiplier;
    } else {
      currentY += hexSize * 1.5 * spacingMultiplier;
    }
    rowCount++;
  }

  for (int i = 0; i < rowPositions.size(); i++) {
    float y = rowPositions.get(i);
    for (float x = -hexSize; x < width + hexSize; x += horizontalSpacing) {
      float xOffset = (i % 2 == 0) ? 0 : offsetAmount;
      drawHexagon(x + xOffset, y, hexSize);
    }
  }

  for (int i = 0; i < rowPositions.size(); i++) {
    float y = rowPositions.get(i);
    boolean squaresAtTop = i % 2 == 1;

    for (float x = -hexSize; x < width + hexSize; x += horizontalSpacing) {
      float xOffset = (i % 2 == 0) ? 0 : offsetAmount;

      if (squaresAtTop) {
        drawSquare(x + xOffset, y - hexSize * 0.7);
      } else {
        drawSquare(x + xOffset, y + hexSize * 0.7);
      }
    }
  }
}

void drawHexagon(float cx, float cy, float s) {
  pushMatrix();
  translate(cx, cy);

  fill(213, 90, 36);
  hexShape(s);

  fill(0);
  hexShape(s * 0.7);

  fill(154, 19, 29);
  hexShape(s * 0.4);

  popMatrix();
}

void drawSquare(float cx, float cy) {
  pushMatrix();
  translate(cx, cy);
  scale(1,1.2);

  fill(0);
  squareShape();

  popMatrix();
}

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
