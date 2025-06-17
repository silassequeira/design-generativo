class Config {
    // Number of cables to create initially
    int cableCount = 30;

    // Downward force applied to cable segments
    float gravity = 0.01;

    // Cable stiffness
    int tension = 5;

    // Number of points that make up each cable
    int cableSegments = 12;

    // Visual thickness of the cables when drawn
    int cableThickness = 4;

    // Size of the cable end connectors
    int connectorRadius = 12;

    // Physics damping factor
    float dampening = 0.98;

    // Background color
    color backgroundColor = color(20, 20, 30);

    // Animation settings
    int connectionInterval = 1000;  // Time between connections/disconnections
    int connectionDuration = 1000;  // Duration of connection animation
    
    // Min and max values for gravity oscillation
    float[] autoGravityRange = {0.05, 0.25};

    // Min and max values for tension oscillation
    float[] autoTensionRange = {2, 6};
}
