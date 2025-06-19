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
    final int imgWidth = sourceImage.width;
    final int imgHeight = sourceImage.height;
    
    // Create potential positions in a grid pattern
    final int gridSpacing = floor(max(10, min(imgWidth, imgHeight) / 40));
    ArrayList<PVector> jackPositions = createGridPositions(imgWidth, imgHeight, gridSpacing);
    
    // Create jacks with strategic placement
    createJacksAtPositions(jackPositions);
    
    // Add supplemental jacks in sparse areas
    addSupplementalJacks();
  }
  
  ArrayList<PVector> createGridPositions(int width, int height, int spacing) {
    ArrayList<PVector> positions = new ArrayList<PVector>();
    
    for (int x = spacing; x < width; x += spacing) {
      for (int y = spacing; y < height; y += spacing) {
        positions.add(new PVector(x, y));
      }
    }
    
    // Shuffle the positions for more natural placement
    return shuffleArray(positions);
  }
  
  void createJacksAtPositions(ArrayList<PVector> positions) {
    int jacksPlaced = 0;
    int i = 0;
    
    while (jacksPlaced < config.maxJacks && i < positions.size()) {
      PVector pos = positions.get(i++);
      
      // Calculate placement probability based on image features
      float placementProbability = calculatePlacementProbability(pos);
      
      if (random(1) < placementProbability) {
        // Create the jack with slight randomization
        float x = pos.x + random(-2, 2);
        float y = pos.y + random(-2, 2);
        Jack jack = new Jack(x, y, jacks.size());
        jacks.add(jack);
        jacksPlaced++;
      }
    }
  }
  
  float calculatePlacementProbability(PVector pos) {
    int x = int(pos.x);
    int y = int(pos.y);
    
    // Start with base probability
    float probability = 0.1;
    
    // Higher probability near edges
    float edgeValue = red(imageAnalyzer.edgeMap.get(x, y));
    if (edgeValue > 200) {
      probability += 0.6;
    }
    
    // Prefer high-contrast areas
    float contrast = imageAnalyzer.getLocalContrast(x, y);
    probability += contrast * 0.3;
    
    // Favor very dark or bright areas
    float brightness = red(imageAnalyzer.brightnessMap.get(x, y));
    if (brightness < 50 || brightness > 200) {
      probability += 0.2;
    }
    
    return probability;
  }
  
  void addSupplementalJacks() {
    if (imageAnalyzer.sourceImage == null) return;
    
    PImage sourceImage = imageAnalyzer.sourceImage;
    
    // Create grid to track jack density
    final int cellSize = 30;
    final int cols = ceil(sourceImage.width / float(cellSize));
    final int rows = ceil(sourceImage.height / float(cellSize));
    int[] jackDensity = new int[rows * cols];
    
    // Count jacks in each cell
    for (Jack jack : jacks) {
      int col = floor(jack.x / cellSize);
      int row = floor(jack.y / cellSize);
      int index = row * cols + col;
      if (index >= 0 && index < jackDensity.length) {
        jackDensity[index]++;
      }
    }
    
    // Add jacks to low-density areas
    addJacksToLowDensityAreas(jackDensity, rows, cols, cellSize);
  }
  
  void addJacksToLowDensityAreas(int[] jackDensity, int rows, int cols, int cellSize) {
    final int additionalJacks = min(300, int(config.maxJacks * 0.3));
    int added = 0;
    
    // First add to empty cells
    for (int i = 0; i < jackDensity.length && added < additionalJacks; i++) {
      if (jackDensity[i] < 1) {
        if (addJackToCell(i, cols, cellSize)) added++;
      }
    }
    
    // Then add to sparse cells
    for (int i = 0; i < jackDensity.length && added < additionalJacks; i++) {
      if (jackDensity[i] == 1) {
        if (addJackToCell(i, cols, cellSize)) added++;
      }
    }
  }
  
  boolean addJackToCell(int cellIndex, int cols, int cellSize) {
    int row = floor(cellIndex / cols);
    int col = cellIndex % cols;
    float x = col * cellSize + random(5, cellSize - 5);
    float y = row * cellSize + random(5, cellSize - 5);
    
    // Ensure it's within image bounds
    PImage img = imageAnalyzer.sourceImage;
    if (x >= 0 && x < img.width && y >= 0 && y < img.height) {
      Jack jack = new Jack(x, y, jacks.size());
      jacks.add(jack);
      return true;
    }
    return false;
  }
  
  void drawJacks() {
    if (!config.showJacks) return;
    
    for (Jack jack : jacks) {
      jack.draw(config);
    }
  }
  
  Jack getJack(int id) {
    if (id >= 0 && id < jacks.size()) {
      return jacks.get(id);
    }
    return null;
  }
  
  void resetJackConnections() {
    for (Jack jack : jacks) {
      jack.reset();
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

class Jack {
  float x, y;
  boolean fixed;
  boolean isJack;
  int id;
  int connections;
  
  Jack(float x, float y, int id) {
    this.x = x;
    this.y = y;
    this.fixed = true;
    this.isJack = true;
    this.id = id;
    this.connections = 0;
  }
  
  void draw(Config config) {
    if (!config.showJacks) return;
    
    noStroke();
    fill(255, 30);
    circle(x, y, config.jackRadius * 2);
  }
  
  void connect() {
    connections++;
  }
  
  void reset() {
    connections = 0;
  }
}
