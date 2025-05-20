float x1, y1, cx2, cy2, cx3, cy3, x4, y4; // Bezier control points
float t = 0; // Adjustable t
float tStep = 0.01; // How much t changes per key press

void setup() {
  size(600, 400);
  noFill();
  
  // Define Bezier points
  x1 = 50;     y1 = height - 50;   // Start point
  cx2 = 150;   cy2 = 50;           // Control point 1
  cx3 = 450;   cy3 = 350;          // Control point 2
  x4 = width - 50; y4 = 50;        // End point
}

void draw() {
  background(240);
  
  // Draw Bezier curve
  stroke(0);
  strokeWeight(2);
  bezier(x1, y1, cx2, cy2, cx3, cy3, x4, y4);
  
  // Draw control points
  stroke(255, 0, 0);
  strokeWeight(6);
  point(x1, y1);  
  point(cx2, cy2);
  point(cx3, cy3);
  point(x4, y4);

  // Draw control lines
  stroke(200, 100, 100);
  strokeWeight(1);
  line(x1, y1, cx2, cy2);
  line(cx2, cy2, cx3, cy3);
  line(cx3, cy3, x4, y4);

  // Calculate ball position on the curve
  float px = bezierPoint(x1, cx2, cx3, x4, t);
  float py = bezierPoint(y1, cy2, cy3, y4, t);
  
  // Display t value and ball coordinates on screen
  fill(0);
  textSize(16);
  text("t: " + nf(t, 0, 2), 20, 20);
  text("px: " + nf(px, 0, 1) + " , py: " + nf(py, 0, 1), 20, 40);
  
  // Draw moving ball
  fill(0, 100, 255);
  noStroke();
  ellipse(px, py, 15, 15);
}

// Keyboard controls to change t
void keyPressed() {
  if (keyCode == RIGHT) {
    t += tStep; // Increase t (move forward)
    if (t > 1) t = 1; // Clamp to max
  } else if (keyCode == LEFT) {
    t -= tStep; // Decrease t (move backward)
    if (t < 0) t = 0; // Clamp to min
  }
}
