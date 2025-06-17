class FloatingImage {
  PImage img;
  float x, y;            // Position
  float targetX, targetY; // Target position for smooth movement
  float easing = 0.02;    // How quickly to approach target position
  float rotation = 0;     // Current rotation angle
  float rotationSpeed;    // How fast the image rotates
  
  FloatingImage(PImage img, float x, float y) {
    this.img = img;
    this.x = x;
    this.y = y;
    this.targetX = x;
    this.targetY = y;
    
    // Random rotation speed
    this.rotationSpeed = random(-0.01, 0.01);
  }
  
  void update() {
    // Move toward target position
    x += (targetX - x) * easing;
    y += (targetY - y) * easing;
    
    // Update rotation
    rotation += rotationSpeed;
    
    // Occasionally change target position
    if (random(100) < 1) {
      targetX = random(img.width/2, width - img.width/2);
      targetY = random(img.height/2, height - img.height/2);
    }
    
    // Boundary checking
    if (x < img.width/2) targetX = img.width/2;
    if (y < img.height/2) targetY = img.height/2;
    if (x > width - img.width/2) targetX = width - img.width/2;
    if (y > height - img.height/2) targetY = height - img.height/2;
  }
  
  void draw() {
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    imageMode(CENTER);
    image(img, 0, 0);
    popMatrix();
  }
  
  // Get the center point in screen coordinates
  PVector getCenter() {
    return new PVector(x, y);
  }
}
