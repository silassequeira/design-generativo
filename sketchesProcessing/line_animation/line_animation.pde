color[] cores = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

float lineSpacing = 40;
float scroll = 0;

void setup() {
  fullScreen();
  frameRate(60);
  rectMode(CENTER);
}

void draw() {
  background(20);

  drawRoad();  
  scroll += 2;
}

void drawRoad() {
  for (int i = 0; i < height / lineSpacing + 2; i++) {
    float y = (i * lineSpacing - scroll % lineSpacing);
    fill(cores[i % cores.length]);
    rect(width/2, y, width * 0.8, 10);
  }
}
