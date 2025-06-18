SynthVisualizer visualizer;

void setup() {
  size(1200, 800);
  // Use fullScreen() instead of size() if you want fullscreen
  // fullScreen();
  visualizer = new SynthVisualizer();
  visualizer.setup();
}

void draw() {
  visualizer.draw();
}

void windowResized() {
  // In Processing, this would be handled differently
  // For web export we can use this special function
  visualizer.windowResized();
}

void keyPressed() {
  if (key >= '0' && key <= '4') {
    // Change the color palette with number keys
    int paletteNumber = key - '0';
    visualizer.config.selectedPalette = paletteNumber;
    println("Switched to palette: " + paletteNumber);
  }
  
  // Toggle random color mode
  if (key == 'r' || key == 'R') {
    visualizer.config.useRandomColorFromPalette = !visualizer.config.useRandomColorFromPalette;
    println("Random color mode: " + visualizer.config.useRandomColorFromPalette);
  }
}
