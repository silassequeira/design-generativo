class Config {
    // Number of cables to create initially
    int cableCount = 12;

    // Downward force applied to cable segments (higher = more drooping)
    float gravity = 0.01;

    // Cable stiffness - higher values make cables less flexible (1-20)
    int tension = 5;

    // Number of points that make up each cable (more = smoother but slower)
    int cableSegments = 12;

    // Visual thickness of the cables when drawn
    int cableThickness = 4;

    // Size of the connection jacks
    int jackRadius = 15;

    // Size of the cable end connectors
    int connectorRadius = 12;

    // Physics damping factor (0-1) - lower values make cables more bouncy
    float dampening = 0.98;

    // Background color in RGB format
    color backgroundColor = color(20, 20, 30);

    // Jack color when not connected
    color jackColor = color(215, 206, 197);
    
    int selectedPalette = 0;
    
    // Whether to select from all colors in a palette or just one random color
    boolean useRandomColorFromPalette = true;

    // Animation settings
    // Time in milliseconds between automatic connection/disconnection events
    int connectionInterval = 1500;

    // Duration in milliseconds for connection/disconnection animations to complete
    int connectionDuration = 1000;

    // Min and max values for gravity oscillation over time for organic movement
    float[] autoGravityRange = {0.05, 0.25};

    // Min and max values for tension oscillation over time for organic movement
    float[] autoTensionRange = {2, 6};
}
