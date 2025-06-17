color[] palette = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120)    // Blue
};

String quote = "All work and no play makes Jack a dull boy.";
PFont font;
float lineHeight;
int totalLines;

// Track all active columns
ArrayList<Column> columns;
int nextColumnStartTime;
int columnDelay = 1000; // milliseconds between new columns

class Column {
  float x;
  int currentLine;
  color textColor;
  boolean isComplete;
  ArrayList<String> lines;
  
  Column(float xPos) {
    x = xPos;
    currentLine = 0;
    textColor = palette[int(random(palette.length))];
    isComplete = false;
    lines = new ArrayList<String>();
  }
  
  void update() {
    if (!isComplete && frameCount % 2 == 0) { // Every other frame
      if (currentLine < totalLines) {
        lines.add(quote);
        currentLine++;
      } else {
        isComplete = true;
      }
    }
  }
  
  void display() {
    fill(textColor);
    for (int i = 0; i < lines.size(); i++) {
      text(lines.get(i), x, 30 + i * lineHeight);
    }
  }
  
  boolean canFitNewColumn(float newX, float textWidth) {
    return abs(newX - x) > textWidth + 50; // More padding to prevent overlap
  }
}

void setup() {
  fullScreen();
  background(0);
  
  font = createFont("Courier", 24);
  textFont(font);
  textSize(24);
  textAlign(LEFT, TOP);
  
  lineHeight = textAscent() + textDescent() + 10;
  totalLines = int((height - 60) / lineHeight); // Leave some margin
  
  columns = new ArrayList<Column>();
  nextColumnStartTime = millis() + columnDelay;
  
  frameRate(30);
}

void draw() {
  background(0);
  
  // Update all existing columns
  for (Column col : columns) {
    col.update();
    col.display();
  }
  
  // Try to start a new column
  if (millis() > nextColumnStartTime) {
    startNewColumn();
    nextColumnStartTime = millis() + columnDelay;
  }
  
  // Remove completed columns if we need space and have too many
  if (columns.size() > 6) { // Reduced limit to ensure better spacing
    removeOldestCompletedColumn();
  }
}

void startNewColumn() {
  float textWidth = textWidth(quote);
  float minSpacing = textWidth + 80; // Generous spacing
  float maxX = width - textWidth - 50;
  
  // Try to find a good position for new column
  for (int attempts = 0; attempts < 100; attempts++) {
    float newX = random(50, maxX);
    boolean canPlace = true;
    
    // Check if this position conflicts with existing columns
    for (Column col : columns) {
      if (abs(newX - col.x) < minSpacing) {
        canPlace = false;
        break;
      }
    }
    
    if (canPlace) {
      columns.add(new Column(newX));
      return;
    }
  }
  
  // If we couldn't find a good spot, remove oldest column and try again
  if (removeOldestCompletedColumn()) {
    // Try one more time after removal with a systematic approach
    ArrayList<Float> usedPositions = new ArrayList<Float>();
    for (Column col : columns) {
      usedPositions.add(col.x);
    }
    
    // Find the largest gap
    if (usedPositions.size() > 0) {
      usedPositions.sort(null);
      
      // Check gaps between existing columns
      for (int i = 0; i < usedPositions.size() - 1; i++) {
        float gapStart = usedPositions.get(i) + textWidth + 40;
        float gapEnd = usedPositions.get(i + 1) - 40;
        
        if (gapEnd - gapStart >= textWidth) {
          float newX = gapStart + random(0, gapEnd - gapStart - textWidth);
          columns.add(new Column(newX));
          return;
        }
      }
      
      // Check space at the beginning or end
      if (usedPositions.get(0) - 50 >= textWidth + 80) {
        float newX = random(50, usedPositions.get(0) - textWidth - 40);
        columns.add(new Column(newX));
        return;
      }
      
      float lastPos = usedPositions.get(usedPositions.size() - 1);
      if (width - lastPos - textWidth - 50 >= textWidth + 80) {
        float newX = random(lastPos + textWidth + 40, width - textWidth - 50);
        columns.add(new Column(newX));
        return;
      }
    }
  }
}

boolean removeOldestCompletedColumn() {
  // First try to remove completed columns
  for (int i = 0; i < columns.size(); i++) {
    if (columns.get(i).isComplete) {
      columns.remove(i);
      return true;
    }
  }
  
  // If no completed columns, remove the oldest one
  if (columns.size() > 0) {
    columns.remove(0);
    return true;
  }
  
  return false;
}

// Interactive controls
void keyPressed() {
  if (key == ' ') {
    // Space to pause/resume
    if (isLooping()) {
      noLoop();
    } else {
      loop();
    }
  } else if (key == 'r' || key == 'R') {
    // R to restart
    background(0);
    columns.clear();
    nextColumnStartTime = millis() + columnDelay;
  } else if (key == 'c' || key == 'C') {
    // C to clear all completed columns
    for (int i = columns.size() - 1; i >= 0; i--) {
      if (columns.get(i).isComplete) {
        columns.remove(i);
      }
    }
  } else if (key == 's' || key == 'S') {
    // S to save screenshot
    save("typewriter_" + year() + month() + day() + hour() + minute() + second() + ".png");
  }
}
