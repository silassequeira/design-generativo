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
