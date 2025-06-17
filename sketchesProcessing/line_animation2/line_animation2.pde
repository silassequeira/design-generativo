color[] cores = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120),   // Blue
  color(215, 206, 197)   // White Grey
};

int numColunas = 40;
float[] xPos;

void setup() {
  fullScreen();
  xPos = new float[numColunas];
  for (int i = 0; i < numColunas; i++) {
    xPos[i] = map(i, 0, numColunas, -100, width);
  }
  strokeCap(ROUND);
  frameRate(60);
}

void draw() {
  background(20);
  float speed = 4;

  for (int i = 0; i < numColunas; i++) {
    float x = xPos[i];

    float centerY = height / 2;
    float spacing = 30 + sin(frameCount * 0.05 + i) * 5;
    float offset = (i - numColunas/2.0) * spacing;

    float lineY1 = centerY + offset * 0.5;
    float lineY2 = centerY - offset * 0.5;

    float lineWeight = 2 + 5 * abs(sin(radians(frameCount * 2 + i * 10)));
    strokeWeight(lineWeight);
    stroke(cores[i % cores.length]);

    line(x, lineY1, x + 10, lineY2);

    // Atualiza posição
    xPos[i] += speed;
    if (xPos[i] > width + 20) {
      xPos[i] = -20;
    }
  }
}
