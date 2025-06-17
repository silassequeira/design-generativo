ImageCableVisualizer visualizer;

void setup() {
  size(1200, 800);
  // Use fullScreen() instead of size() if you want fullscreen
  // fullScreen();
  visualizer = new ImageCableVisualizer();
  visualizer.setup();
}

void draw() {
  visualizer.draw();
}
