class Config {
    constructor() {
        // Number of cables to create initially
        this.cableCount = 12;

        // Downward force applied to cable segments (higher = more drooping)
        this.gravity = 0.01;

        // Cable stiffness - higher values make cables less flexible (1-20)
        this.tension = 5;

        // Number of points that make up each cable (more = smoother but slower)
        this.cableSegments = 12;

        // Visual thickness of the cables when drawn
        this.cableThickness = 4;

        // Size of the connection jacks
        this.jackRadius = 15;

        // Size of the cable end connectors
        this.connectorRadius = 12;

        // Physics damping factor (0-1) - lower values make cables more bouncy
        this.dampening = 0.98;

        // Background color in RGB format [R, G, B]
        this.backgroundColor = [20, 20, 30];

        // Jack color in RGB format [R, G, B] when not connected
        this.jackColor = [215, 206, 197];

        // Animation settings
        // Time in milliseconds between automatic connection/disconnection events
        this.connectionInterval = 1500;

        // Duration in milliseconds for connection/disconnection animations to complete
        this.connectionDuration = 1000;

        // Min and max values for gravity oscillation over time for organic movement
        this.autoGravityRange = [0.05, 0.25];

        // Min and max values for tension oscillation over time for organic movement
        this.autoTensionRange = [2, 6];
    }
}