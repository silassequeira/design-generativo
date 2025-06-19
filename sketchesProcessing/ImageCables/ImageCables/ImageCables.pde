// Main Processing sketch
ReconstructionSystem reconstructionSystem;

void setup() {
  // Set the size of the window
  fullScreen();
    pixelDensity(1);
  // For high-res displays, might be better than pixelDensity(1)
  // If you have a high-res display, you can uncomment the next line
  surface.setResizable(true);
  
  // Create the reconstruction system
  reconstructionSystem = new ReconstructionSystem(this);
  
  // Load the image - Processing doesn't have preload
reconstructionSystem.loadImage("the_shining_maze.png");

  // Initialize ++the reconstruction system
  reconstructionSystem.initialize(width, height);
  
  // Set frameRate for smoother animation
  frameRate(16);
}

void draw() {
  // Update the reconstruction system
  reconstructionSystem.update();
  
  // Draw the reconstruction system
  reconstructionSystem.draw();
}

void keyPressed() {
  reconstructionSystem.handleKeyPressed(key);
}

void windowResized() {
  // Not built-in for Processing, we need to simulate this
  // This will be called if you implement the Processing window resize library
  // or use surface.setResizable(true) and detect size changes
  reconstructionSystem.handleWindowResized(width, height);
}
