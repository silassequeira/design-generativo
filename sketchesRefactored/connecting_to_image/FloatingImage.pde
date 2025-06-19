class FloatingImage {
    PImage img;
    float x, y;            // Position
    float targetX, targetY; // Target position for smooth movement
    float easing = 0.02;    // How quickly to approach target position
    float rotation = 0;     // Current rotation angle
    float rotationSpeed;    // How fast the image rotates
    float scaleX;           // Scale X
    float scaleY;           // Scale Y
    boolean isStatic = true; // Flag to determine if image stays in fixed position
    
    //Constructor Overloading - provide different ways to create a FloatingImage object
    
    FloatingImage(PImage img, float x, float y) {
        this.img = img;
        this.x = x;
        this.y = y;
        this.targetX = x;
        this.targetY = y;
        this.rotationSpeed = 0;
        this.scaleX = 1.0;
        this.scaleY = 1.0;
    }
    
    FloatingImage(PImage img, float x, float y, boolean isStatic, float scale) {
        this(img, x, y);
        this.isStatic = isStatic;
        this.scaleX = scale;
        this.scaleY = scale;
    }
    
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
        if (!isStatic) {
            updatePosition();
        }
        
        rotation += rotationSpeed;
    }
    
    void updatePosition() {
        // Move toward target position
        x += (targetX - x) * easing;
        y += (targetY - y) * easing;
        
        // Occasionally change target position
        if (random(100) < 1) {
            setRandomTarget();
        }
        
        enforceBoundaries();
    }
    
    void setRandomTarget() {
        targetX = random(img.width/2, width - img.width/2);
        targetY = random(img.height/2, height - img.height/2);
    }
    
    void enforceBoundaries() {
        if (x < img.width/2) targetX = img.width/2;
        if (y < img.height/2) targetY = img.height/2;
        if (x > width - img.width/2) targetX = width - img.width/2;
        if (y > height - img.height/2) targetY = height - img.height/2;
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
    
    PVector getCenter() {
        return new PVector(x, y);
    }
}
