class Config {
  // Display settings
  color backgroundColor = color(20, 20, 30);    // Background color (very dark gray, almost black)
  boolean showJacks = false;            // When true, displays connection points as small circles
  boolean showOriginalImage = false;    // When true, shows original image behind cable reconstruction
  boolean showProgressPercentage = false; // When true, displays completion percentage counter
  boolean progressiveRendering = true;  // When true, adds cables gradually; when false, renders all at once
  
  // Component settings
  int maxJacks = 4500;                   // Maximum number of connection points to generate from the image
  int jackRadius = 3;                   // Visual size of the jack points when displayed
  float edgeThreshold = 40;             // Sensitivity for edge detection (higher = only stronger edges)
  int colorPalette = 17;                // Number of colors to extract from the image
  int cableCount = 5500;                 // Total number of cables to generate for the reconstruction
  int cableThickness = 3;               // Visual thickness of drawn cables in pixels
  float minCableLength = 90;            // Minimum allowed distance between connected jacks
  float maxCableLength = 400;           // Maximum allowed distance between connected jacks
  int maxConnectionsPerJack = 8;       // Maximum number of cables that can connect to a single jack
  int cablesPerFrame = 3;               // Number of cables to add per animation frame during progressive rendering
  int colorSamples = 123;                // Number of points to sample along cables when evaluating color and edges
  float edgePreference = 1;           // Weight given to edge following (higher = prioritize cables on edges)
  int alpha = 200;                      // Transparency level of cables (0-255) for visual layering
  
  /**
   * Constructor with default values
   */
  Config() {
    // Default values are set above
  }
  
  /**
   * Toggles the specified display property
   * @param property Name of the property to toggle
   */
  void toggle(String property) {
    if (property.equals("showJacks")) {
      showJacks = !showJacks;
    } else if (property.equals("showOriginalImage")) {
      showOriginalImage = !showOriginalImage;
    } else if (property.equals("progressiveRendering")) {
      progressiveRendering = !progressiveRendering;
    } else if (property.equals("showProgressPercentage")) {
      showProgressPercentage = !showProgressPercentage;
    }
  }
}
