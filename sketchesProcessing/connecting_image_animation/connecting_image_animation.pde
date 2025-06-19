ImageCableVisualizer visualizer;

void setup() {
  fullScreen();
  visualizer = new ImageCableVisualizer();
  visualizer.setup();
}

void draw() {
  visualizer.draw();
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
