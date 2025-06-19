class Cable {
  FloatingImage targetImage;
  float startX, startY;
  Config config;
  color cableColor;
  ArrayList<CablePoint> points;
  float connectionProgress;
  float disconnectionProgress;

  Cable(float startX, float startY, FloatingImage targetImage, Config config) {
    this.startX = startX;
    this.startY = startY;
    this.targetImage = targetImage;
    this.config = config;
    this.cableColor = config.generateCableColor();
    this.points = this.createCablePoints();
    this.connectionProgress = 0;
    this.disconnectionProgress = 0;
  }
  
  ArrayList<CablePoint> createCablePoints() {
    ArrayList<CablePoint> cablePoints = new ArrayList<CablePoint>();

    // Get target center
    PVector target = targetImage.getCenter();

    // Start point (fixed)
    CablePoint startPoint = new CablePoint();
    startPoint.x = startX;
    startPoint.y = startY;
    startPoint.prevX = startX;
    startPoint.prevY = startY;
    startPoint.fixed = true;
    startPoint.isConnector = true;
    cablePoints.add(startPoint);

    // Calculate direct distance
    float directDistance = dist(startX, startY, target.x, target.y);

    // Create more segments for longer cables
    int segmentCount = this.config.cableSegments + floor(directDistance / 200);

    // Generate cable segments with droop
    for (int i = 1; i < segmentCount; i++) {
      float t = (float) i / segmentCount;

      // Create a drooping curve effect
      float x = lerp(startX, target.x, t);
      float y = lerp(startY, target.y, t);

      // Add droop to the cable
      float droopFactor = directDistance / 2.5;
      float droop = sin(t * PI) * droopFactor;

      // Apply droop - pull down more in the middle
      y += droop;

      // Add randomness for a natural look
      if (i > 1 && i < segmentCount - 1) {
        x += random(-20, 20);
        y += random(-10, 30); // Bias downward
      }

      CablePoint midPoint = new CablePoint();
      midPoint.x = x;
      midPoint.y = y;
      midPoint.prevX = x;
      midPoint.prevY = y;
      midPoint.fixed = false;
      cablePoints.add(midPoint);
    }

    // End point (fixed at target center)
    CablePoint endPoint = new CablePoint();
    PVector center = targetImage.getCenter();
    endPoint.x = center.x;
    endPoint.y = center.y;
    endPoint.prevX = center.x;
    endPoint.prevY = center.y;
    endPoint.fixed = true;
    endPoint.isConnector = true;
    cablePoints.add(endPoint);

    return cablePoints;
  }

  void updatePhysics() {
    // Update endpoint position to follow the moving image
    PVector target = targetImage.getCenter();
    CablePoint endPoint = points.get(points.size() - 1);
    endPoint.x = target.x;
    endPoint.y = target.y;
    endPoint.prevX = target.x;
    endPoint.prevY = target.y;

    // Update positions using Verlet integration
    for (int i = 1; i < points.size() - 1; i++) {
      CablePoint p = points.get(i);
      if (!p.fixed) {
        // Calculate velocity from previous position
        float vx = (p.x - p.prevX) * this.config.dampening;
        float vy = (p.y - p.prevY) * this.config.dampening;

        // Save current position as previous
        p.prevX = p.x;
        p.prevY = p.y;

        // Apply velocity and gravity
        p.x += vx;
        p.y += vy + this.config.gravity;
      }
    }

    // Enforce cable segment length constraints
    int constraintIterations = this.config.tension;
    for (int iteration = 0; iteration < constraintIterations; iteration++) {
      for (int i = 0; i < points.size() - 1; i++) {
        CablePoint p1 = points.get(i);
        CablePoint p2 = points.get(i + 1);

        // Calculate distance between points
        float dx = p2.x - p1.x;
        float dy = p2.y - p1.y;
        float currentDistance = sqrt(dx * dx + dy * dy);

        // Make rest distance a bit longer than needed for slack
        float excessFactor = 1.3 + sin(i * 0.5) * 0.1;
        float restDistance = 25 * excessFactor;

        // Calculate the difference from rest length
        float difference = (restDistance - currentDistance) / currentDistance;

        // Apply a relaxed correction
        float relaxFactor = 0.25;
        float offsetX = dx * relaxFactor * difference;
        float offsetY = dy * relaxFactor * difference;

        // Move points to maintain cable segment length
        if (!p1.fixed) {
          p1.x -= offsetX;
          p1.y -= offsetY;
        }
        if (!p2.fixed) {
          p2.x += offsetX;
          p2.y += offsetY;
        }
      }
    }
  }

  void draw() {
    // Draw the cable
    stroke(this.cableColor);
    strokeWeight(this.config.cableThickness);
    noFill();

    beginShape();
    for (CablePoint p : points) {
      vertex(p.x, p.y);
    }
    endShape();

    // Draw connectors
    drawConnectors();
  }

  void drawConnection() {
    int lastIndex = floor(lerp(0, points.size() - 1, connectionProgress));

    if (lastIndex <= 0) return;

    stroke(this.cableColor);
    strokeWeight(this.config.cableThickness);
    noFill();

    beginShape();
    for (int i = 0; i <= lastIndex; i++) {
      vertex(points.get(i).x, points.get(i).y);
    }

    if (lastIndex < points.size() - 1) {
      float partialProgress = (connectionProgress * (points.size() - 1)) % 1;
      CablePoint nextPoint = points.get(lastIndex + 1);
      CablePoint currentPoint = points.get(lastIndex);
      float x = lerp(currentPoint.x, nextPoint.x, partialProgress);
      float y = lerp(currentPoint.y, nextPoint.y, partialProgress);
      vertex(x, y);
    }

    endShape();
  }

  void drawDisconnection() {
    int firstIndex = floor(lerp(0, points.size() - 1, disconnectionProgress));

    if (firstIndex >= points.size() - 1) return;

    stroke(this.cableColor);
    strokeWeight(this.config.cableThickness);
    noFill();

    beginShape();

    if (firstIndex > 0) {
      float partialProgress = (disconnectionProgress * (points.size() - 1)) % 1;
      CablePoint prevPoint = points.get(firstIndex - 1);
      CablePoint currentPoint = points.get(firstIndex);
      float x = lerp(prevPoint.x, currentPoint.x, partialProgress);
      float y = lerp(prevPoint.y, currentPoint.y, partialProgress);
      vertex(x, y);
    }

    for (int i = firstIndex; i < points.size(); i++) {
      vertex(points.get(i).x, points.get(i).y);
    }

    endShape();
  }

  void drawConnectors() {
    // Get first and last points of the cable
    CablePoint startPoint = points.get(0);
    CablePoint endPoint = points.get(points.size() - 1);

    // Draw connectors
    drawConnector(startPoint);
    drawConnector(endPoint);
  }

  void drawConnector(CablePoint point) {
    // Extract base color from the cable color
    float r = red(this.cableColor);
    float g = green(this.cableColor);
    float b = blue(this.cableColor);

    // Draw connector
    fill(215, 206, 197);
    stroke(30);
    strokeWeight(1);
    circle(point.x, point.y, this.config.connectorRadius);

    // Draw connector details
    fill(20);
    noStroke();
    circle(point.x, point.y, this.config.connectorRadius * 0.5);

    // Draw subtle colored highlight
    fill(r, g, b, 100);
    noStroke();
    circle(point.x, point.y, this.config.connectorRadius * 0.3);
  }

  boolean updateConnectionProgress(float deltaTime) {
    this.connectionProgress += deltaTime / this.config.connectionDuration;
    return this.connectionProgress >= 1;
  }

  boolean updateDisconnectionProgress(float deltaTime) {
    this.disconnectionProgress += deltaTime / this.config.connectionDuration;
    return this.disconnectionProgress >= 1;
  }
}

// Helper class for cable points
class CablePoint {
  float x, y;           // Current position
  float prevX, prevY;   // Previous position
  boolean fixed;        // Whether this point can move
  boolean isConnector;  // Whether this is an end connector

  CablePoint() {
    isConnector = false;
  }
}

// Helper class to store disconnection information
class DisconnectionProgress {
  Cable cable;
  int index;

  DisconnectionProgress(Cable cable, int index) {
    this.cable = cable;
    this.index = index;
  }
}
