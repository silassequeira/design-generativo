ImageCableVisualizer visualizer;

void setup() {
  fullScreen();
  visualizer = new ImageCableVisualizer();
  visualizer.setup();
}

void draw() {
  visualizer.draw();
}
