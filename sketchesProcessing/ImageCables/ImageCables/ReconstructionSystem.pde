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
    
    if (!imageAnalyzer.imageLoaded) {
      println("Cannot initialize - image not loaded");
      return false;
    }
    
    // Resize image to fill the canvas completely
    imageAnalyzer.resizeImage(canvasWidth, canvasHeight);
    
    // Analyze the source image
    imageAnalyzer.analyzeImage();
    
    // Generate color clusters from the image
    imageAnalyzer.generateColorClusters();
    
    // Reset simulation
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
    
    // Plan all cables but don't add them immediately for progressive rendering
    cableGenerator.planCablesFromImage();
    
    println("Created " + jackManager.jacks.size() + " jacks and planned " + 
           cableGenerator.pendingCables.size() + " cables");
  }
  
  void update() {
    if (!initialized) return;
    
    // Progressive rendering - add cables gradually
    cableGenerator.addCablesProgressively();
  }
  
  void draw() {
    if (!initialized) {
      // Show loading message
      background(0);
      fill(255);
      textSize(20);
      textAlign(CENTER, CENTER);
      text("Loading image...", width / 2, height / 2);
      return;
    }
    
    background(config.backgroundColor);
    
    // Draw cables
    cableGenerator.drawCables();
    
    // Draw jacks
    jackManager.drawJacks();
    
    // Display progress only if the option is enabled
    if (config.showProgressPercentage && cableGenerator.pendingCables.size() > 0) {
      float progress = cableGenerator.getProgress();
      fill(255);
      noStroke();
      textSize(14);
      textAlign(LEFT, TOP);
      text("Progress: " + floor(progress) + "%", 10, 10);
    }
  }
  
  void handleKeyPressed(char key) {
    switch (key) {
      case 'r':
      case 'R':
        resetSimulation();
        break;
        
      case 'j':
      case 'J':
        config.toggle("showJacks");
        break;
        
      case 'i':
      case 'I':
        config.toggle("showOriginalImage");
        break;
        
      case 'p':
      case 'P':
        config.toggle("progressiveRendering");
        if (!config.progressiveRendering) {
          // Add all pending cables immediately
          cableGenerator.addAllCablesImmediately();
        }
        break;
        
      case '+':
      case '=':
        config.cableCount += 100;
        resetSimulation();
        break;
        
      case '-':
      case '_':
        config.cableCount = max(50, config.cableCount - 100);
        resetSimulation();
        break;
    }
  }
  
  void handleWindowResized(int newWidth, int newHeight) {
    canvasWidth = newWidth;
    canvasHeight = newHeight;
    
    if (imageAnalyzer.sourceImage != null) {
      // Resize image to fill the canvas completely
      imageAnalyzer.resizeImage(canvasWidth, canvasHeight);
      
      // Re-analyze image and reset simulation
      imageAnalyzer.analyzeImage();
      imageAnalyzer.generateColorClusters();
      resetSimulation();
    }
  }
}
