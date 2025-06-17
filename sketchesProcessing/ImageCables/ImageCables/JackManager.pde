class JackManager {
  Config config;
  ImageAnalyzer imageAnalyzer;
  ArrayList<Jack> jacks;
  
  JackManager(Config config, ImageAnalyzer imageAnalyzer) {
    this.config = config;
    this.imageAnalyzer = imageAnalyzer;
    this.jacks = new ArrayList<Jack>();
  }
  
  void createJacksFromImage() {
    jacks.clear();
    
    if (!imageAnalyzer.imageLoaded) return;
    
    PImage sourceImage = imageAnalyzer.sourceImage;
    
    // Get image dimensions
    final int imgWidth = sourceImage.width;
    final int imgHeight = sourceImage.height;
    
    // Calculate grid spacing based on image size
    final int gridSpacing = floor(max(10, min(imgWidth, imgHeight) / 40));
    ArrayList<PVector> jackPositions = new ArrayList<PVector>();
    
    // Create a grid of potential positions
    for (int x = gridSpacing; x < imgWidth; x += gridSpacing) {
      for (int y = gridSpacing; y < imgHeight; y += gridSpacing) {
        jackPositions.add(new PVector(x, y));
      }
    }
    
    // Shuffle the positions
    jackPositions = shuffleArray(jackPositions);
    
    // Create jacks with strategic placement
    int jacksPlaced = 0;
    int i = 0;
    
    while (jacksPlaced < config.maxJacks && i < jackPositions.size()) {
      PVector pos = jackPositions.get(i);
      i++;
      
      // Sample edge value and brightness
      float edgeValue = red(imageAnalyzer.edgeMap.get(int(pos.x), int(pos.y)));
      float brightness = red(imageAnalyzer.brightnessMap.get(int(pos.x), int(pos.y)));
      
      // Higher probability near edges and in areas with more contrast
      float placementProbability = 0.1; // Base probability
      
      if (edgeValue > 200) {
        placementProbability += 0.6; // Much higher on edges
      }
      
      // Prefer areas with high contrast
      float contrast = imageAnalyzer.getLocalContrast(int(pos.x), int(pos.y));
      placementProbability += contrast * 0.3;
      
      // Add probability based on brightness - favor areas with more detail
      if (brightness < 50 || brightness > 200) {
        placementProbability += 0.2; // Higher in very dark or bright areas
      }
      
      if (random(1) < placementProbability) {
        // Create the jack with a small random offset for more natural appearance
        Jack jack = new Jack();
        jack.x = pos.x + random(-2, 2);
        jack.y = pos.y + random(-2, 2);
        jack.fixed = true;
        jack.isJack = true;
        jack.id = jacks.size();
        jack.connections = 0;
        
        jacks.add(jack);
        jacksPlaced++;
      }
    }
    
    // Add some additional jacks in areas with few jacks
    addSupplementalJacks();
  }
  
void addSupplementalJacks() {
  if (imageAnalyzer.sourceImage == null) return;
  
  PImage sourceImage = imageAnalyzer.sourceImage;
  
  // First identify areas with low jack density
  final int cellSize = 30;  // Smaller cell size (was 40)
  final int rows = ceil(sourceImage.height / float(cellSize));
  final int cols = ceil(sourceImage.width / float(cellSize));
  int[] grid = new int[rows * cols];
  
  // Count jacks in each cell
  for (Jack jack : jacks) {
    int col = floor(jack.x / cellSize);
    int row = floor(jack.y / cellSize);
    int index = row * cols + col;
    if (index >= 0 && index < grid.length) {
      grid[index]++;
    }
  }
  
  // Add jacks in cells with few or no jacks - more aggressive supplemental filling
  final int additionalJacks = min(300, int(config.maxJacks * 0.3));  // Increased from 0.2 to 0.3
  int added = 0;
  
  // First, add to completely empty cells
  for (int i = 0; i < grid.length && added < additionalJacks; i++) {
    if (grid[i] < 1) {  // Empty cells
      addSupplementalJackToCell(i, cols, cellSize, sourceImage);
      added++;
    }
  }
  
  // Then add to sparse cells if we still have room
  if (added < additionalJacks) {
    for (int i = 0; i < grid.length && added < additionalJacks; i++) {
      if (grid[i] == 1) {  // Cells with just one jack
        addSupplementalJackToCell(i, cols, cellSize, sourceImage);
        added++;
      }
    }
  }
}

// Helper method to add a jack to a specific cell
private void addSupplementalJackToCell(int cellIndex, int cols, int cellSize, PImage sourceImage) {
  int row = floor(cellIndex / cols);
  int col = cellIndex % cols;
  float x = col * cellSize + random(5, cellSize - 5);
  float y = row * cellSize + random(5, cellSize - 5);
  
  // Make sure it's within image bounds
  if (x >= 0 && x < sourceImage.width && y >= 0 && y < sourceImage.height) {
    Jack jack = new Jack();
    jack.x = x;
    jack.y = y;
    jack.fixed = true;
    jack.isJack = true;
    jack.id = jacks.size();
    jack.connections = 0;
    
    jacks.add(jack);
  }
}
  
  void drawJacks() {
    if (!config.showJacks) return;
    
    // Draw jack points
    noStroke();
    fill(255, 30);
    for (Jack jack : jacks) {
      circle(jack.x, jack.y, config.jackRadius * 2);
    }
  }
  
  Jack getJack(int id) {
    for (Jack jack : jacks) {
      if (jack.id == id) return jack;
    }
    return null;
  }
  
  void resetJackConnections() {
    for (Jack jack : jacks) {
      jack.connections = 0;
    }
  }
  
  // Utility function to shuffle an array
  ArrayList<PVector> shuffleArray(ArrayList<PVector> array) {
    ArrayList<PVector> newArray = new ArrayList<PVector>(array);
    for (int i = newArray.size() - 1; i > 0; i--) {
      int j = floor(random(i + 1));
      PVector temp = newArray.get(i);
      newArray.set(i, newArray.get(j));
      newArray.set(j, temp);
    }
    return newArray;
  }
}

// Jack representation class
class Jack {
  float x, y;
  boolean fixed;
  boolean isJack;
  int id;
  int connections;
}
