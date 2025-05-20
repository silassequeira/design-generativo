float x1, y1, cx2, cy2, cx3, cy3, x4, y4; // Bezier control points
float t = 0; // Curve parameter (0 to 1)
float baseSpeed = 0.004; // Base movement speed
float gravity = 0.0008; // Increased gravity constant for more dramatic effects
float currentSpeed; // To track and display the current speed

// Variables for speed visualization
int[] speedHistory = new int[100];
int historyIndex = 0;

void setup() {
  size(600, 400);
  noFill();
  // Define Bezier points
  x1 = 50;     y1 = height - 50;   // Start point
  cx2 = 150;   cy2 = 50;           // Control point 1
  cx3 = 450;   cy3 = 350;          // Control point 2
  x4 = width - 50; y4 = 50;        // End point
  
  // Initialize speed history
  for (int i = 0; i < speedHistory.length; i++) {
    speedHistory[i] = 0;
  }
}

void draw() {
  background(240);
  
  // Draw Bezier curve
  stroke(150);
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
  
  // Normalize the tangent vector
  float magnitude = sqrt(tx*tx + ty*ty);
  tx /= magnitude;
  ty /= magnitude;
  
  // Calculate the slope angle (relative to horizontal)
  float slope = atan2(ty, tx);
  
  // Calculate gravitational effect (maximum at downward slopes)
  // Apply a larger multiplier for more dramatic effect
  float gravityEffect = sin(slope) * gravity;
  
  // Calculate final speed - faster when going down, slower when going up
  // The power function makes the effect more dramatic
  currentSpeed = baseSpeed - (gravityEffect * 3.5); 
  
  // Ensure minimum speed to prevent getting stuck
  currentSpeed = max(currentSpeed, 0.0005);
  
  // Apply a maximum speed cap to prevent too fast movement on steep downhills
  currentSpeed = min(currentSpeed, 0.012);
  
  // Update speed history for visualization
  speedHistory[historyIndex] = int(map(currentSpeed, 0.0005, 0.012, 0, 50));
  historyIndex = (historyIndex + 1) % speedHistory.length;
  
  // Draw speed graph
  stroke(50, 100, 200);
  fill(50, 100, 200, 100);
  beginShape();
  vertex(width - speedHistory.length - 10, height - 20);
  for (int i = 0; i < speedHistory.length; i++) {
    vertex(width - speedHistory.length - 10 + i, height - 20 - speedHistory[(historyIndex + i) % speedHistory.length]);
  }
  vertex(width - 10, height - 20);
  endShape(CLOSE);
  
  // Draw speed graph outline
  noFill();
  stroke(0, 50, 150);
  beginShape();
  for (int i = 0; i < speedHistory.length; i++) {
    vertex(width - speedHistory.length - 10 + i, height - 20 - speedHistory[(historyIndex + i) % speedHistory.length]);
  }
  endShape();
  
  // Draw moving ball
  // Change ball size based on speed for additional visual feedback
  float ballSize = map(currentSpeed, 0.0005, 0.012, 10, 20);
  
  // Change ball color based on speed (blue when slow, red when fast)
  float speedRatio = map(currentSpeed, 0.0005, 0.012, 0, 1);
  fill(speedRatio * 255, 100 * (1-speedRatio), 255 * (1-speedRatio));
  
  noStroke();
  ellipse(px, py, ballSize, ballSize);
  
  // Draw a speed trail
  float prevX, prevY;
  float stepBack = 0.01;
  stroke(150, 150, 150, 100);
  for (int i = 1; i <= 10; i++) {
    float trailT = max(0, t - stepBack * i * (1/currentSpeed));
    if (trailT < 0) continue;
    
    prevX = bezierPoint(x1, cx2, cx3, x4, trailT);
    prevY = bezierPoint(y1, cy2, cy3, y4, trailT);
    
    // Smaller points for trail
    float trailSize = ballSize * (1 - i/12.0);
    fill(speedRatio * 255, 100 * (1-speedRatio), 255 * (1-speedRatio), 150 - i*12);
    ellipse(prevX, prevY, trailSize, trailSize);
  }
  
  // Update position along the curve
  t += currentSpeed;
  if (t > 1) t = 0; // Loop back
  
  // Display current speed value
  fill(150);
  textSize(14);
  text("Speed: " + nf(currentSpeed * 1000, 0, 2), 20, 20);
  text("Speed Graph", width - 90, height - 30);
}
