// Main colors and specialized palettes
color[] mainPalette = {
  color(35, 139, 47),    // Green
  color(255, 102, 0),    // Orange
  color(206, 73, 46),    // Orange Dark
  color(226, 190, 82),   // Yellow
  color(247, 236, 205),  // Yellow Light
  color(79, 121, 120)    // Blue
};

color[] redPalette = {
  color(229, 0, 0),      // Vibrant red
  color(204, 0, 0),      // Classic red
  color(178, 0, 0),      // Deeper red
  color(153, 0, 0),      // Rich red
  color(127, 0, 0),      // Burgundy red
  color(102, 0, 0)       // Dark maroon
};

color[] greenPalette = {
  color(0, 229, 0),      // Lime green
  color(0, 204, 0),      // Bright green
  color(0, 178, 0),      // Natural green
  color(0, 153, 0),      // Forest green
  color(0, 127, 0),      // Dark green
  color(0, 102, 0)       // Hunter green
};

color[] orangePalette = {
color(215, 206, 197), // White Grey
color(226, 190, 82),  // Yellow
color(247, 236, 205), // Yellow Light
color(255, 102, 0),   // Orange
color(230, 149, 0),   // Traditional orange
color(205, 133, 0),   // Muted orange
color(206, 73, 46),   // Burnt orange
color(155, 102, 0),   // Earthy orange
color(130, 87, 0),   // Brownish orange
color(231, 200, 109)    // Brownish orange
};

color[] bluePalette = {
  color(0, 153, 255),    // Vibrant blue
  color(0, 122, 204),    // Medium blue
  color(0, 92, 163),     // Traditional blue
  color(0, 61, 122),     // Darker blue
  color(0, 31, 82),      // Navy blue
  color(0, 0, 41)        // Black-blue
};

// Store all palettes in an array for easy switching
color[][] allPalettes = {mainPalette, redPalette, greenPalette, orangePalette, bluePalette};
int activePaletteIndex = 4; // Start with main colors

String quote = "All work and no play makes Jack a dull boy.";

PFont font;
float lineHeight;
int totalLines;

// Track all active columns
ArrayList<Column> columns;
int nextColumnStartTime;
int columnDelay = 6000; // milliseconds between new columns

class Column {
  float x;
  int currentLine;
  int colorIndex; // Store the index into the palette rather than a specific color
  boolean isComplete;
  ArrayList<String> lines;
  
  Column(float xPos) {
    x = xPos;
    currentLine = 0;
    // Just store the index, not the actual color
    colorIndex = int(random(allPalettes[activePaletteIndex].length));
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
    // Get the color from the current active palette using the stored index
    color textColor = allPalettes[activePaletteIndex][colorIndex % allPalettes[activePaletteIndex].length];
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
  background(20, 20, 30);
  
  font = createFont("Courier", 24);
  textFont(font);
  textSize(30);
  textAlign(LEFT, TOP);
  
  lineHeight = textAscent() + textDescent() + 10;
  totalLines = int((height - 20) / lineHeight); // Leave some margin
  
  columns = new ArrayList<Column>();
  nextColumnStartTime = millis() + columnDelay;
  
  frameRate(12);
}

void draw() {
  background(20, 20, 30);
  
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

String getPaletteName(int index) {
  String[] names = {"Main Colors", "Red", "Green", "Orange", "Blue"};
  return names[index];
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
  // Number keys 1-5 for palette switching
  if (key >= '1' && key <= '5') {
    int selectedIndex = key - '1'; // Convert key to index (0-4)
    if (selectedIndex < allPalettes.length) {
      activePaletteIndex = selectedIndex;
      // Note: This only affects future columns, not existing ones
    }
  }
  else if (key == ' ') {
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
