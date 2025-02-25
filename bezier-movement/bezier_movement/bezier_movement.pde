float x1, y1, cx2, cy2, cx3, cy3, x4, y4; // Bezier control points
float t = 0; // Time variable (0 to 1)
float speed = 0.005; // Speed of movement

void setup() {
  size(600, 400);
  noFill();
  
  // Define fixed control points
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
  point(x1, y1);  // Start
  point(cx2, cy2); // Control 1
  point(cx3, cy3); // Control 2
  point(x4, y4);  // End
  
  // Draw control lines
  stroke(200, 100, 100);
  strokeWeight(1);
  line(x1, y1, cx2, cy2);
  line(cx2, cy2, cx3, cy3);
  line(cx3, cy3, x4, y4);

  // Add text labels
  fill(0);
  textSize(14);
  text("Start (P0)", x1 - 30, y1 + 15);
  text("Control 1 (P1)", cx2 - 40, cy2 - 10);
  text("Control 2 (P2)", cx3 - 40, cy3 + 20);
  text("End (P3)", x4 - 30, y4 - 10);

  // Calculate ball position on the curve
  float px = bezierPoint(x1, cx2, cx3, x4, t);
  float py = bezierPoint(y1, cy2, cy3, y4, t);
  
  // Draw moving ball
  fill(0, 100, 255);
  noStroke();
  ellipse(px, py, 15, 15);
  
  // Update position along the curve
  t += speed;
  if (t > 1) t = 0; // Loop back
}



//x1  (float)  coordinates for the first anchor point
//y1  (float)  coordinates for the first anchor point
//z1  (float)  coordinates for the first anchor point
//x2  (float)  coordinates for the first control point
//y2  (float)  coordinates for the first control point
//z2  (float)  coordinates for the first control point
//x3  (float)  coordinates for the second control point
//y3  (float)  coordinates for the second control point
//z3  (float)  coordinates for the second control point
//x4  (float)  coordinates for the second anchor point
//y4  (float)  coordinates for the second anchor point
//z4  (float)  coordinates for the second anchor point
