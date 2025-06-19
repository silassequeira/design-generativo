class FloatingImage {
  PImage img;
  float x, y;            // Position
  float targetX, targetY; // Target position for smooth movement
  float easing = 0.02;    // How quickly to approach target position
  float rotation = 0;     // Current rotation angle
  float rotationSpeed; 
  float randomScale=random(5,5);
  float scaleX = randomScale;     // Scale X (default 1.2)
  float scaleY = randomScale;     // Scale Y (default 1.2)
  boolean isStatic = true; // Flag to determine if image stays in fixed position
  
  // Original constructor
  FloatingImage(PImage img, float x, float y) {
    this.img = img;
    this.x = x;
    this.y = y;
    this.targetX = x;
    this.targetY = y;
    
    // Random rotation speed
    this.rotationSpeed = 0;
  }
  
  // Extended constructor with static option and scale
  FloatingImage(PImage img, float x, float y, boolean isStatic, float scale) {
    this(img, x, y); // Call the basic constructor
    this.isStatic = isStatic;
    this.scaleX = scale;
    this.scaleY = scale;
  }
  
  // Additional constructor with separate X and Y scaling
  FloatingImage(PImage img, float x, float y, boolean isStatic, float scaleX, float scaleY) {
    this(img, x, y); // Call the basic constructor
    this.isStatic = isStatic;
    this.scaleX = scaleX;
    this.scaleY = scaleY;
  }
  
  // Methods to set properties after creation
  void setStatic(boolean isStatic) {
    this.isStatic = isStatic;
  }
  
  void setScale(float scale) {
    this.scaleX = scale;
    this.scaleY = scale;
  }
  
  void setScale(float scaleX, float scaleY) {
    this.scaleX = scaleX;
    this.scaleY = scaleY;
  }
  
  void update() {
    // Skip position updates if static
    if (!isStatic) {
      // Move toward target position
      x += (targetX - x) * easing;
      y += (targetY - y) * easing;
      
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
    
    // Always update rotation (even for static images)
    rotation += rotationSpeed;
  }
  
  void draw() {
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    scale(scaleX, scaleY);
    imageMode(CENTER);
    image(img, 0, 0);
    popMatrix();
  }
  
  // Get the center point in screen coordinates
  PVector getCenter() {
    return new PVector(x, y);
  }
}
