class Config {
    constructor() {
        // Visualization settings
        this.cableCount = 3000;       // Target number of cables
        this.cablesPerFrame = 3;      // How many cables to add each frame
        this.cableThickness = 2;      // Line thickness
        this.jackRadius = 2;          // Small jacks
        this.showJacks = false;       // Don't show connection points by default
        this.backgroundColor = [20, 20, 30];
        this.alpha = 140;             // Alpha value for lines (transparency)

        // Image analysis settings
        this.edgeThreshold = 70;      // Threshold for edge detection
        this.jackDensity = 0.7;       // Higher density for better coverage
        this.maxJacks = 1000;         // More jacks for detailed reproduction
        this.imageInfluence = 0.9;    // Stronger image influence
        this.colorSamples = 17;       // More color samples for better color representation
        this.minCableLength = 30;     // Shorter minimum cables for more detail
        this.maxCableLength = 300;    // Shorter max length to avoid cross-image cables
        this.edgePreference = 1.8;    // How much to prefer edge-following paths
        this.colorPalette = 17;       // Number of color clusters to use

        // Performance settings
        this.maxConnectionsPerJack = 5; // Limit connections per point to avoid clutter
        this.progressiveRendering = true; // Enable progressive building of the image
        this.showOriginalImage = false;   // Toggle to show original image
    }

    // Update a config value and trigger any necessary updates
    updateSetting(key, value) {
        if (this.hasOwnProperty(key)) {
            this[key] = value;
            return true;
        }
        return false;
    }

    // Toggle boolean settings
    toggle(key) {
        if (this.hasOwnProperty(key) && typeof this[key] === 'boolean') {
            this[key] = !this[key];
            return true;
        }
        return false;
    }
}