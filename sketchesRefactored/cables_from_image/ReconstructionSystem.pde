class ReconstructionSystem {
  Config config;
  ImageAnalyzer imageAnalyzer;
  JackManager jackManager;
  CableGenerator cableGenerator;
  
  int canvasWidth = 0;
  int canvasHeight = 0;
  boolean initialized = false;
  
  ReconstructionSystem(PApplet sketch) {
    config = new Config();
    imageAnalyzer = new ImageAnalyzer(config, sketch);
    jackManager = new JackManager(config, imageAnalyzer);
    cableGenerator = new CableGenerator(config, imageAnalyzer, jackManager);
  }
  
  void loadImage(String path) {
    imageAnalyzer.loadImage(path);
  }
  
  boolean initialize(int canvasWidth, int canvasHeight) {
    this.canvasWidth = canvasWidth;
    this.canvasHeight = canvasHeight;
    
    // Set up the system
    imageAnalyzer.resizeImage(canvasWidth, canvasHeight);
    imageAnalyzer.analyzeImage();
    imageAnalyzer.generateColorClusters();
    
    resetSimulation();
    
    initialized = true;
    return true;
  }
  
  void resetSimulation() {
    if (!imageAnalyzer.imageLoaded) return;
    
    println("Resetting simulation...");
    
    // Reset components
    jackManager.jacks.clear();
    cableGenerator.reset();
    
    // Create jacks based on image features
    jackManager.createJacksFromImage();
    
    // Plan cables
    cableGenerator.planCablesFromImage();
  }
  
  void update() {
    if (!initialized) return;
    
    // Progressive rendering - add cables gradually
    cableGenerator.addCablesProgressively();
  }
  
  void draw() {
    if (!initialized) {
      drawLoadingScreen();
      return;
    }
    
    background(config.backgroundColor);
    
    // Draw cables
    cableGenerator.drawCables();
    
    // Draw jacks
    jackManager.drawJacks();
    
  }
  
  void drawLoadingScreen() {
    background(0);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("Loading image...", width / 2, height / 2);
  }
  
  void drawProgressIndicator() {
    float progress = cableGenerator.getProgress();
    fill(255);
    noStroke();
    textSize(14);
    textAlign(LEFT, TOP);
    text("Progress: " + floor(progress) + "%", 10, 10);
  }
  
  void handleWindowResized(int newWidth, int newHeight) {
    canvasWidth = newWidth;
    canvasHeight = newHeight;
    
    if (imageAnalyzer.sourceImage != null) {
      imageAnalyzer.resizeImage(canvasWidth, canvasHeight);
      imageAnalyzer.analyzeImage();
      imageAnalyzer.generateColorClusters();
      resetSimulation();
    }
  }
}
