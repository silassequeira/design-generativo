class Config {
    // Cable creation
    int cableCount = 300;

    // Physics parameters
    float gravity = 0.01;
    int tension = 5;
    float dampening = 0.98;

    // Cable appearance
    int cableSegments = 12;
    int cableThickness = 4;
    int connectorRadius = 12;

    // Background color
    color backgroundColor = color(20, 20, 30);
    
    // Color palette settings
    int selectedPalette = 3;
    // Animation settings
    int connectionInterval = 500;  // Time between connections/disconnections
    int connectionDuration = 300;  // Duration of connection animation
    
    // Dynamic physics parameters
    float[] autoGravityRange = {0.05, 0.25};
    float[] autoTensionRange = {2, 6};
    
    // Get the current color palette
    ArrayList<Integer> getColorPalette() {
        ArrayList<Integer> colors = new ArrayList<Integer>();

        switch (selectedPalette) {
            case 0: // Main Colors
                colors.add(color(35, 139, 47));   // Green
                colors.add(color(255, 102, 0));   // Orange
                colors.add(color(206, 73, 46));   // Orange Dark
                colors.add(color(226, 190, 82));  // Yellow
                colors.add(color(247, 236, 205)); // Yellow Light
                colors.add(color(79, 121, 120));  // Blue
                colors.add(color(215, 206, 197)); // White Grey
                break;

            case 1: // Red Palette
                colors.add(color(206, 73, 46));   // Orange Dark
                colors.add(color(229, 0, 0));     // Vibrant red
                colors.add(color(204, 0, 0));     // Classic red
                colors.add(color(178, 0, 0));     // Deeper red
                colors.add(color(153, 0, 0));     // Rich red
                colors.add(color(127, 0, 0));     // Deep red
                colors.add(color(102, 0, 0));     // Dark maroon
                break;

            case 2: // Green Palette
                colors.add(color(35, 139, 47));   // Green
                colors.add(color(0, 229, 0));     // Vibrant green
                colors.add(color(0, 204, 0));     // Bright green
                colors.add(color(0, 178, 0));     // Natural green
                colors.add(color(0, 153, 0));     // Forest green
                colors.add(color(0, 127, 0));     // Deep green
                colors.add(color(0, 102, 0));     // Hunter green
                break;

            case 3: // Orange Palette
                colors.add(color(215, 206, 197)); // White Grey
                colors.add(color(226, 190, 82));  // Yellow
                colors.add(color(247, 236, 205)); // Yellow Light
                colors.add(color(255, 102, 0));   // Orange
                colors.add(color(230, 149, 0));   // Traditional orange
                colors.add(color(205, 133, 0));   // Muted orange
                colors.add(color(206, 73, 46));   // Burnt orange
                colors.add(color(155, 102, 0));   // Earthy orange
                colors.add(color(130, 87, 0));    // Brownish orange
                colors.add(color(231, 200, 109)); // Light yellow
                break;

            case 4: // Blue Palette
                colors.add(color(0, 153, 255));   // Vibrant blue
                colors.add(color(0, 122, 204));   // Medium blue
                colors.add(color(0, 92, 163));    // Traditional blue
                colors.add(color(0, 61, 122));    // Rich blue
                colors.add(color(208, 129, 100)); // Pink
                colors.add(color(120, 84, 216));  // Purple
                colors.add(color(255, 102, 0));   // Orange
                colors.add(color(140, 247, 219)); // Teal
                break;

            default: // Default to main colors
                colors.add(color(35, 139, 47));   // Green
                colors.add(color(255, 102, 0));   // Orange
                colors.add(color(226, 190, 82));  // Yellow
                colors.add(color(79, 121, 120));  // Blue
        }

        return colors;
    }
    
    color generateCableColor() {
        ArrayList<Integer> palette = getColorPalette();
            int colorIndex = floor(random(palette.size()));
            return color(palette.get(colorIndex), 220);
    }
}
