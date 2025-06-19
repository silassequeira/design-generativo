ReconstructionSystem reconstructionSystem;

void setup() {
  fullScreen();
  pixelDensity(1);
  surface.setResizable(true);
  
  reconstructionSystem = new ReconstructionSystem(this);
  reconstructionSystem.loadImage("the_shining_maze.png");
  reconstructionSystem.initialize(width, height);
  
  frameRate(16);
}

void draw() {
  reconstructionSystem.update();
  reconstructionSystem.draw();
}
