float x1, y1, cx2, cy2, cx3, cy3, x4, y4; // Bezier control points
float t = 0;
float speed = 0.005; // Adjust speed

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
  
  // Calculate tangent vector
  float tx = bezierTangent(x1, cx2, cx3, x4, t);
  float ty = bezierTangent(y1, cy2, cy3, y4, t);
  
  // Normalize the tangent vector for drawing
  float magnitude = sqrt(tx * tx + ty * ty);
  float nx = tx / magnitude * 30;  // Scale for visibility
  float ny = ty / magnitude * 30;
  
  float movement = (baseSpeed * magnitude) / 5;  // Scaling factor to adjust sensitivity


  // Draw tangent vector
  stroke(0, 255,0 );
  strokeWeight(2);
  line(px, py, px + nx, py + ny);

  // Draw moving ball
  fill(0, 100, 255);
  noStroke();
  ellipse(px, py, 15, 15);
  
  // Update position along the curve
  t += speed;
  if (t > 1) t = 0; // Loop back
}


//bezierTangent(x1, cx2, cx3, x4, t) → Gets tangent vector (tx, ty) at t.
//magnitude = sqrt(tx * tx + ty * ty); → Computes length of the tangent vector.
//movement = speed / magnitude; → Adjusts speed so movement along the curve remains uniform.
