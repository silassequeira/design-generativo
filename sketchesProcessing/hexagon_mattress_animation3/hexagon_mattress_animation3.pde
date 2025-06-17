class HexagonUnit {
  float hexX, hexY;
  float rectX, rectY;
  float size;
  float startTime = -1;
  boolean isTopRow;
  
  HexagonUnit(float hexX, float hexY, float rectX, float rectY, float size, boolean isTopRow) {
    this.hexX = hexX;
    this.hexY = hexY;
    this.rectX = rectX;
    this.rectY = rectY;
    this.size = size;
    this.isTopRow = isTopRow;
  }
  
  void activate(float time) {
    if (startTime < 0) {
      startTime = time;
    }
  }
  
  void draw(float currentTime) {
    if (startTime < 0) return;
    
    float progress = constrain((currentTime - startTime) / 800.0, 0, 1);
    
    // Draw hexagon with original colors
    drawAnimatedHexagon(hexX, hexY, size, progress);
    
    // Draw rectangle with original color
    drawAnimatedRectangle(rectX, rectY, progress);
  }
  
  void drawAnimatedHexagon(float cx, float cy, float size, float progress) {
    pushMatrix();
    translate(cx, cy);
    
    // Scale animation with easing
    float scale = 1 - pow(1 - progress, 3); // Cubic easing
    scale(scale);
    
    // Original hexagon colors
    fill(213, 90, 36); // Outer hexagon
    hexShape(size);
    
    fill(0); // Middle layer
    hexShape(size * 0.7);
    
    fill(154, 19, 29); // Inner hexagon
    hexShape(size * 0.4);
    
    popMatrix();
  }
  
  void drawAnimatedRectangle(float cx, float cy, float progress) {
    pushMatrix();
    translate(cx, cy);
    
    // Scale animation with easing
    float scale = 1 - pow(1 - progress, 3); // Cubic easing
    scale(1, 1.2 * scale); // Maintain original vertical scaling
    
    // Original rectangle color
    fill(0);
    rect(-size/6, -size/4, size/3, size/2);
    
    popMatrix();
  }
}

float hexSize = 50;
float spacingMultiplier = 1.2;
ArrayList<HexagonUnit> units = new ArrayList<HexagonUnit>();
float activationSpeed = 0.03;
boolean animationComplete = false;

void setup() {
  fullScreen();
  noStroke();
  smooth();
  
  calculateGridPositions();
}

void draw() {
  background(0);
  
  // Activate random units
  int activated = 0;
  for (HexagonUnit unit : units) {
    if (unit.startTime < 0 && random(1) < activationSpeed) {
      unit.activate(millis());
      activated++;
    }
  }
  
  // Draw all activated units
  for (HexagonUnit unit : units) {
    unit.draw(millis());
  }
  
  // Check if animation is complete
  if (!animationComplete && activated == 0) {
    animationComplete = true;
    for (HexagonUnit unit : units) {
      if (unit.startTime < 0) {
        animationComplete = false;
        break;
      }
    }
  }
}

void calculateGridPositions() {
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
  
  // Create unified units (hexagon + rectangle)
  for (int i = 0; i < rowPositions.size(); i++) {
    float y = rowPositions.get(i);
    float xOffset = (i % 2 == 0) ? 0 : offsetAmount;
    boolean isTopRow = i % 2 == 1;
    float rectY = isTopRow ? y - hexSize * 0.7 : y + hexSize * 0.7;
    
    for (float x = -hexSize; x < width + hexSize; x += horizontalSpacing) {
      HexagonUnit unit = new HexagonUnit(
        x + xOffset, y, 
        x + xOffset, rectY, 
        hexSize, isTopRow
      );
      units.add(unit);
    }
  }
}

void hexShape(float r) {
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i + PI / 6;
    vertex(cos(angle) * r, sin(angle) * r);
  }
  endShape(CLOSE);
}

void mousePressed() {
  // Reset animation on mouse click
  for (HexagonUnit unit : units) {
    unit.startTime = -1;
  }
  animationComplete = false;
}
