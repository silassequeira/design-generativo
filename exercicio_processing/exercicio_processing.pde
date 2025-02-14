Bola[] bol;
int n = 10;
float ang, alfa = TWO_PI/n;
boolean roda = false;

void setup() {
  size(500, 500);
  frameRate(30);  // Control animation speed
  initializeBolas();
}

void initializeBolas() {
  bol = new Bola[n];
  for (int i = 0; i < n; i++) {
    createNewBola(i);
  }
}

void createNewBola(int index) {
  // Generate unique random control points
  float x1 = random(width);
  float cx2 = random(width);
  float cx3 = random(width);
  float x4 = random(width);
  float y1 = random(height);
  float cy2 = random(height);
  float cy3 = random(height);
  float y4 = random(height);
  float r1 = random(10, 50);
  color c1 = color(random(255), random(255), random(255));
  
  bol[index] = new Bola(x1, cx2, cx3, x4, y1, cy2, cy3, y4, r1, c1);
}

void draw() {
  smooth();

  for (int i = 0; i < n; i++) {
    bol[i].desenha();
    // Add some movement to existing circles
    bol[i].jiggleControlPoints(2);
  }
}