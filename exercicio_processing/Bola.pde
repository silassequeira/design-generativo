class Bola {
  float r;
  float x1, cx2, cx3, x4;
  float y1, cy2, cy3, y4;
  float px, py;
  float tx, ty;
  float t = 0;
  float speed = 0.02; // Speed initialized here
  float magnitude;
  float movement;
  color c;

  Bola(float x1, float cx2, float cx3, float x4, float y1, float cy2, float cy3, float y4, float r1, color c1) {
    this.x1 = x1;
    this.cx2 = cx2;
    this.cx3 = cx3;
    this.x4 = x4;
    this.y1 = y1;
    this.cy2 = cy2;
    this.cy3 = cy3;
    this.y4 = y4;
    this.r = r1;
    this.c = c1;
    // Initial position
    updatePosition();
  }

  void desenha() {
    strokeWeight(movement);
    ellipseMode(CENTER);
    fill(c);

    // Calculate tangent and movement based on current t
    tx = bezierTangent(x1, cx2, cx3, x4, t);
    ty = bezierTangent(y1, cy2, cy3, y4, t);
    magnitude = sqrt(tx * tx + ty * ty);
    movement = speed / magnitude;

    t += movement;
    if (t > 1) t = 0;

    // Update position to new t
    updatePosition();

    ellipse(px, py, r*speed*3, r*speed*3);
  }

  void updatePosition() {
    px = bezierPoint(x1, cx2, cx3, x4, t);
    py = bezierPoint(y1, cy2, cy3, y4, t);
  }

  // Optional method to animate the Bezier path
  void jiggleControlPoints(float amount) {
    x1 += random(-amount, amount);
    cx2 += random(-amount, amount);
    cx3 += random(-amount, amount);
    x4 += random(-amount, amount);
    y1 += random(-amount, amount);
    cy2 += random(-amount, amount);
    cy3 += random(-amount, amount);
    y4 += random(-amount, amount);
    // Keep points within canvas bounds
    x1 = constrain(x1, 0, width);
    cx2 = constrain(cx2, 0, width);
    cx3 = constrain(cx3, 0, width);
    x4 = constrain(x4, 0, width);
    y1 = constrain(y1, 0, height);
    cy2 = constrain(cy2, 0, height);
    cy3 = constrain(cy3, 0, height);
    y4 = constrain(y4, 0, height);
  }

  void rodar() {
    // Implement rotation if needed
  }
}
