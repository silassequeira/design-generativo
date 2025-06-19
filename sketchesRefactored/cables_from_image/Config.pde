class Config {
  // Display settings
  color backgroundColor = color(20, 20, 30);
  boolean progressiveRendering = true;
  boolean showJacks = false;
  
  // Component settings
  int maxJacks = 4500;
  int jackRadius = 3;
  float edgeThreshold = 40;
  int colorPalette = 17;
  int cableCount = 5500;
  int cableThickness = 3;
  float minCableLength = 90;
  float maxCableLength = 400;
  int maxConnectionsPerJack = 8;
  int cablesPerFrame = 3;
  int colorSamples = 123;
  float edgePreference = 1;
  int alpha = 200;
  
  Config() {
    // Default values are already set above
  }
  
}
