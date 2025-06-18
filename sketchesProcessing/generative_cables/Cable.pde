class Cable {
    int start;
    int end;
    Jack startJack;
    Jack endJack;
    Config config;
    color cableColor;
    ArrayList<CablePoint> points;
    int age;
    float connectionProgress;
    float disconnectionProgress;

    Cable(Jack startJack, Jack endJack, Config config) {
        this.start = startJack.id;
        this.end = endJack.id;
        this.startJack = startJack;
        this.endJack = endJack;
        this.config = config;
        this.cableColor = this.generateColor();
        this.points = this.createCablePoints(startJack, endJack);
        this.age = 0;
        this.connectionProgress = 0;
        this.disconnectionProgress = 0;

        // Mark jacks as connected
        startJack.connect();
        endJack.connect();
    }

   color generateColor() {
        // Get the current palette based on config
        ArrayList<Integer> palette = getColorPalette(this.config.selectedPalette);
        
        if (this.config.useRandomColorFromPalette) {
            // Pick a random color from the palette
            int colorIndex = floor(random(palette.size()));
            return color(palette.get(colorIndex), 220); // Adding alpha
        } else {
            // Use the whole palette and pick one color
            int colorIndex = floor(random(palette.size()));
            return color(palette.get(colorIndex), 220);
        }
    }
    
    ArrayList<Integer> getColorPalette(int paletteType) {
        ArrayList<Integer> colors = new ArrayList<Integer>();
        
        switch (paletteType) {
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
                colors.add(color(229, 0, 0));     // Vibrant red
                colors.add(color(204, 0, 0));     // Classic red
                colors.add(color(178, 0, 0));     // Deeper red
                colors.add(color(153, 0, 0));     // Rich red
                colors.add(color(127, 0, 0));     // Deep red
                colors.add(color(102, 0, 0));     // Dark maroon
                break;
                
            case 2: // Green Palette
                colors.add(color(0, 229, 0));     // Vibrant green
                colors.add(color(0, 204, 0));     // Bright green
                colors.add(color(0, 178, 0));     // Natural green
                colors.add(color(0, 153, 0));     // Forest green
                colors.add(color(0, 127, 0));     // Deep green
                colors.add(color(0, 102, 0));     // Hunter green
                break;
                
            case 3: // Orange Palette
                colors.add(color(255, 165, 0));   // Vibrant orange
                colors.add(color(230, 149, 0));   // Traditional orange
                colors.add(color(205, 133, 0));   // Muted orange
                colors.add(color(180, 118, 0));   // Burnt orange
                colors.add(color(155, 102, 0));   // Earthy orange
                colors.add(color(130, 87, 0));    // Brownish orange
                break;
                
            case 4: // Blue Palette
                colors.add(color(0, 153, 255));   // Vibrant blue
                colors.add(color(0, 122, 204));   // Medium blue
                colors.add(color(0, 92, 163));    // Traditional blue
                colors.add(color(0, 61, 122));    // Rich blue
                colors.add(color(0, 31, 82));     // Navy blue
                colors.add(color(0, 0, 41));      // Dark blue
                break;
                
            default: // Default to main colors
                colors.add(color(35, 139, 47));   // Green
                colors.add(color(255, 102, 0));   // Orange
                colors.add(color(226, 190, 82));  // Yellow
                colors.add(color(79, 121, 120));  // Blue
        }
        
        return colors;
    }

    ArrayList<CablePoint> createCablePoints(Jack start, Jack end) {
        ArrayList<CablePoint> cablePoints = new ArrayList<CablePoint>();

        // Start point (fixed at jack)
        CablePoint startPoint = new CablePoint();
        startPoint.x = start.x;
        startPoint.y = start.y;
        startPoint.prevX = start.x;
        startPoint.prevY = start.y;
        startPoint.fixed = true;
        startPoint.isConnector = true;
        cablePoints.add(startPoint);

        // Calculate direct distance for reference
        float directDistance = dist(start.x, start.y, end.x, end.y);

        // Create more segments for longer cables
        int segmentCount = this.config.cableSegments + floor(directDistance / 200);

        // Generate cable segments with significant initial droop
        for (int i = 1; i < segmentCount; i++) {
            float t = (float) i / segmentCount;

            // Create a drooping curve effect
            float x = lerp(start.x, end.x, t);
            float y = lerp(start.y, end.y, t);

            // Add substantial droop to the cable - increase droopFactor
            float droopFactor = directDistance / 2.5; // More aggressive drooping
            float droop = sin(t * PI) * droopFactor;

            // Apply droop - pull down more in the middle
            y += droop;

            // Add significant randomness for a more natural look
            if (i > 1 && i < segmentCount - 1) {
                x += random(-20, 20);
                y += random(-10, 30); // Bias downward
            }

            CablePoint midPoint = new CablePoint();
            midPoint.x = x;
            midPoint.y = y;
            midPoint.prevX = x;
            midPoint.prevY = y;
            midPoint.fixed = false;
            cablePoints.add(midPoint);
        }

        // End point (fixed at jack)
        CablePoint endPoint = new CablePoint();
        endPoint.x = end.x;
        endPoint.y = end.y;
        endPoint.prevX = end.x;
        endPoint.prevY = end.y;
        endPoint.fixed = true;
        endPoint.isConnector = true;
        cablePoints.add(endPoint);

        return cablePoints;
    }

    void updatePhysics() {
        // Update positions using Verlet integration
        for (int i = 0; i < points.size(); i++) {
            CablePoint p = points.get(i);
            if (!p.fixed) {
                // Calculate velocity from previous position
                float vx = (p.x - p.prevX) * this.config.dampening;
                float vy = (p.y - p.prevY) * this.config.dampening;

                // Save current position as previous
                p.prevX = p.x;
                p.prevY = p.y;

                // Apply velocity and gravity
                p.x += vx;
                p.y += vy + this.config.gravity;
            }
        }

        // Enforce cable segment length constraints
        int constraintIterations = this.config.tension;
        for (int iteration = 0; iteration < constraintIterations; iteration++) {
            for (int i = 0; i < points.size() - 1; i++) {
                CablePoint p1 = points.get(i);
                CablePoint p2 = points.get(i + 1);

                // Calculate distance between points
                float dx = p2.x - p1.x;
                float dy = p2.y - p1.y;
                float currentDistance = sqrt(dx * dx + dy * dy);

                // Make rest distance 25-40% longer than needed
                float excessFactor = 1.3 + sin(i * 0.5) * 0.1;  // Varies between 1.2-1.4
                float restDistance = 25 * excessFactor;

                // Calculate the difference from rest length
                float difference = (restDistance - currentDistance) / currentDistance;

                // Apply a more relaxed correction
                float relaxFactor = 0.25;
                float offsetX = dx * relaxFactor * difference;
                float offsetY = dy * relaxFactor * difference;

                // Move points to maintain cable segment length
                if (!p1.fixed) {
                    p1.x -= offsetX;
                    p1.y -= offsetY;
                }
                if (!p2.fixed) {
                    p2.x += offsetX;
                    p2.y += offsetY;
                }
            }
        }
    }

    void draw() {
        // Draw the cable
        stroke(this.cableColor);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();
        for (CablePoint p : points) {
            vertex(p.x, p.y);
        }
        endShape();
    }

    void drawConnection() {
        int lastIndex = floor(lerp(0, points.size() - 1, connectionProgress));

        if (lastIndex <= 0) return;

        // Draw the cable up to the current progress
        stroke(this.cableColor);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();
        for (int i = 0; i <= lastIndex; i++) {
            vertex(points.get(i).x, points.get(i).y);
        }

        // If we're between points, draw to the interpolated position
        if (lastIndex < points.size() - 1) {
            float partialProgress = (connectionProgress * (points.size() - 1)) % 1;
            CablePoint nextPoint = points.get(lastIndex + 1);
            CablePoint currentPoint = points.get(lastIndex);
            float x = lerp(currentPoint.x, nextPoint.x, partialProgress);
            float y = lerp(currentPoint.y, nextPoint.y, partialProgress);
            vertex(x, y);
        }

        endShape();
    }

    void drawDisconnection() {
        int firstIndex = floor(lerp(0, points.size() - 1, disconnectionProgress));

        if (firstIndex >= points.size() - 1) return;

        // Draw the cable from current progress to end
        stroke(this.cableColor);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();

        // If we're between points, start from the interpolated position
        if (firstIndex > 0) {
            float partialProgress = (disconnectionProgress * (points.size() - 1)) % 1;
            CablePoint prevPoint = points.get(firstIndex - 1);
            CablePoint currentPoint = points.get(firstIndex);
            float x = lerp(prevPoint.x, currentPoint.x, partialProgress);
            float y = lerp(prevPoint.y, currentPoint.y, partialProgress);
            vertex(x, y);
        }

        for (int i = firstIndex; i < points.size(); i++) {
            vertex(points.get(i).x, points.get(i).y);
        }

        endShape();
    }

    void drawConnectors() {
        // Get first and last points of the cable
        CablePoint startPoint = points.get(0);
        CablePoint endPoint = points.get(points.size() - 1);

        // Draw connectors
        drawConnector(startPoint);
        drawConnector(endPoint);
    }

    void drawConnector(CablePoint point) {
        // Extract base color from the cable color
        float r = red(this.cableColor);
        float g = green(this.cableColor);
        float b = blue(this.cableColor);

        // Draw connector
        fill(215, 206, 197);
        stroke(30);
        strokeWeight(1);
        circle(point.x, point.y, this.config.connectorRadius);

        // Draw connector details
        fill(20);
        noStroke();
        circle(point.x, point.y, this.config.connectorRadius * 0.5);

        // Draw subtle colored highlight
        fill(r, g, b, 100);
        noStroke();
        circle(point.x, point.y, this.config.connectorRadius * 0.3);
    }

    boolean updateConnectionProgress(float deltaTime) {
        this.connectionProgress += deltaTime / this.config.connectionDuration;
        return this.connectionProgress >= 1;
    }

    boolean updateDisconnectionProgress(float deltaTime) {
        this.disconnectionProgress += deltaTime / this.config.connectionDuration;
        return this.disconnectionProgress >= 1;
    }
}

// Helper class for cable points
class CablePoint {
    float x, y;           // Current position
    float prevX, prevY;   // Previous position
    boolean fixed;        // Whether this point can move
    boolean isConnector;  // Whether this is an end connector
    
    CablePoint() {
        isConnector = false;
    }
}
