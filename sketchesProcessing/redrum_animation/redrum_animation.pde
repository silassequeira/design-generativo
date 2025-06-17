color[] palette = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120)    // Blue
};

PFont font;
float time = 0;
int blinkingIndex = 0;
int blinkTimer = 0;

void setup() {
  fullScreen();
  font = createFont("Courier", 60, true);
  textFont(font);
  textAlign(CENTER, CENTER);
  frameRate(30);
}

void draw() {
  background(0);
  time += 0.03;
  blinkTimer++;

  if (blinkTimer > 60) { // muda a palavra a piscar a cada 2 segundos
    blinkingIndex = (blinkingIndex + 1) % 3;
    blinkTimer = 0;
  }

  for (int i = 0; i < 3; i++) {
    float x = width / 4.0 * (i + 1);
    float y = height / 2.0;
    boolean isBlinking = (i == blinkingIndex);
    drawVerticalWord("REDRUM", x, y, isBlinking);
  }
}

void drawVerticalWord(String word, float x, float centerY, boolean blink) {
  float spacing = 60;
  float totalHeight = word.length() * spacing;
  float startY = centerY - totalHeight / 2;

  for (int i = 0; i < word.length(); i++) {
    float y = startY + i * spacing;

    if (blink) {
      // Piscar: alterna entre visível e invisível
      if (frameCount % 20 < 10) {
        fill(palette[int(random(palette.length))]);
        text(word.charAt(i), x + random(-1, 1), y + random(-1, 1));
      }
    } else {
      fill(palette[int(random(palette.length))]);
      text(word.charAt(i), x + random(-1, 1), y + random(-1, 1));
    }
  }
}
