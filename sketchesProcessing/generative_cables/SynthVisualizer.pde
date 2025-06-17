class SynthVisualizer {
    // Configuration
    Config config;

    // Main variables
    ArrayList<Jack> jacks;
    ArrayList<Cable> cables;
    float canvasWidth;
    float canvasHeight;

    // Animation state
    int lastConnectionTime;
    ArrayList<Cable> connectionsInProgress;
    ArrayList<DisconnectionProgress> disconnectionsInProgress;
    float globalAnimationTime;
    
    // For tracking deltaTime
    int lastFrameTime;

    SynthVisualizer() {
        // Create configuration
        this.config = new Config();

        // Initialize collections
        this.jacks = new ArrayList<Jack>();
        this.cables = new ArrayList<Cable>();
        this.connectionsInProgress = new ArrayList<Cable>();
        this.disconnectionsInProgress = new ArrayList<DisconnectionProgress>();
        this.globalAnimationTime = 0;
    }

    void setup() {
        fullScreen();
        this.canvasWidth = width;
        this.canvasHeight = height;
        
        // Initialize the last frame time
        this.lastFrameTime = millis();

        // Initialize the visualization
        this.resetSimulation();

        // Start with fewer cables so we can see them being created
        if (this.cables.size() > 3) {
            this.cables = new ArrayList<Cable>(this.cables.subList(0, 3));
        }
    }

    void resetSimulation() {
        this.jacks = new ArrayList<Jack>();
        this.cables = new ArrayList<Cable>();
        this.connectionsInProgress = new ArrayList<Cable>();
        this.disconnectionsInProgress = new ArrayList<DisconnectionProgress>();

        // Create fixed connection points (like synthesizer jacks)
        this.createJacks();

        // Create initial cables between random points
        this.createCables();
    }
    
    // Create all jacks in the grid layout
void createJacks() {
    int jackId = 0;
    
    // Calculate dynamic margins based on canvas size
    float horizontalMargin = this.canvasWidth * 0.12;  // 12% of screen width
    float verticalMargin = this.canvasHeight * 0.12;   // 12% of screen height
    
    // Calculate usable area
    float usableWidth = this.canvasWidth - (horizontalMargin * 2);
    float usableHeight = this.canvasHeight - (verticalMargin * 2);

    // Top row of jacks
    int topJackCount = 8;
    for (int i = 0; i < topJackCount; i++) {
        this.jacks.add(new Jack(
            horizontalMargin + (usableWidth / (topJackCount - 1)) * i,
            verticalMargin,
            jackId++,
            this.config
        ));
    }

    // Bottom row of jacks
    int bottomJackCount = 8;
    for (int i = 0; i < bottomJackCount; i++) {
        this.jacks.add(new Jack(
            horizontalMargin + (usableWidth / (bottomJackCount - 1)) * i,
            this.canvasHeight - verticalMargin,
            jackId++,
            this.config
        ));
    }

    // Middle row of jacks
    int middleJackCount = 8;
    for (int i = 0; i < middleJackCount; i++) {
        this.jacks.add(new Jack(
            horizontalMargin + (usableWidth / (middleJackCount - 1)) * i,
            this.canvasHeight / 2,
            jackId++,
            this.config
        ));
    }

    // Left column of jacks
    int leftJackCount = 3;
    for (int i = 0; i < leftJackCount; i++) {
        this.jacks.add(new Jack(
            horizontalMargin,
            verticalMargin + (usableHeight / (leftJackCount + 1)) * (i + 1),
            jackId++,
            this.config
        ));
    }

    // Right column of jacks
    int rightJackCount = 3;
    for (int i = 0; i < rightJackCount; i++) {
        this.jacks.add(new Jack(
            this.canvasWidth - horizontalMargin,
            verticalMargin + (usableHeight / (rightJackCount + 1)) * (i + 1),
            jackId++,
            this.config
        ));
    }
}
    // Rest of the SynthVisualizer class remains the same
    void createCables() {
        // Create cables between random jacks
        for (int i = 0; i < this.config.cableCount; i++) {
            int startIndex = floor(random(this.jacks.size()));
            int endIndex;
            do {
                endIndex = floor(random(this.jacks.size()));
            } while (startIndex == endIndex);

            Jack startJack = this.jacks.get(startIndex);
            Jack endJack = this.jacks.get(endIndex);

            this.cables.add(new Cable(startJack, endJack, this.config));
        }
    }
    void updatePhysics() {
        // Apply physics to each cable
        for (Cable cable : this.cables) {
            cable.updatePhysics();
        }
    }

    void manageConnections() {
        // Calculate deltaTime (in seconds for easier animation timing)
        int currentTime = millis();
        float deltaTime = (currentTime - this.lastFrameTime);
        this.lastFrameTime = currentTime;
        
        this.globalAnimationTime += deltaTime;

        // Vary gravity and tension over time for more organic movement
        float[] gravityRange = this.config.autoGravityRange;
        float[] tensionRange = this.config.autoTensionRange;
        this.config.gravity = map(sin(this.globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
        this.config.tension = floor(map(sin(this.globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]));

        // Update connection animations in progress
        this.updateConnectionAnimations(deltaTime);

        // Check if it's time to make a new connection or disconnection
        if (millis() - this.lastConnectionTime > this.config.connectionInterval) {
            this.lastConnectionTime = millis();

            // Randomly decide to create or remove a connection
            if (random(1) < 0.6 && this.cables.size() < this.config.cableCount) {
                // Create a new connection
                this.createNewConnection();
            } else if (this.cables.size() > 0) {
                // Remove a connection
                this.removeRandomConnection();
            } else {
                this.createNewConnection();
            }
        }
    }

    void createNewConnection() {
        // Find unconnected jacks
        ArrayList<Jack> unconnectedJacks = new ArrayList<Jack>();
        for (Jack jack : this.jacks) {
            if (!jack.connected) {
                unconnectedJacks.add(jack);
            }
        }

        if (unconnectedJacks.size() >= 2) {
            int startIndex = floor(random(unconnectedJacks.size()));
            Jack startJack = unconnectedJacks.get(startIndex);

            // Find jacks that are within a reasonable connection distance
            float maxConnectionDistance = this.canvasWidth / 2;  // Limit how far cables can stretch
            ArrayList<Jack> possibleTargets = new ArrayList<Jack>();
            
            for (int i = 0; i < unconnectedJacks.size(); i++) {
                if (i == startIndex) continue;  // Can't connect to self
                
                Jack jack = unconnectedJacks.get(i);
                // Calculate distance between jacks
                float distance = dist(startJack.x, startJack.y, jack.x, jack.y);
                if (distance < maxConnectionDistance) {
                    possibleTargets.add(jack);
                }
            }

            // If no valid targets found, exit
            if (possibleTargets.size() == 0) return;

            // Choose a random end jack from valid targets
            Jack endJack = possibleTargets.get(floor(random(possibleTargets.size())));

            // Create new connection and add to in-progress list
            Cable newCable = new Cable(startJack, endJack, this.config);
            newCable.connectionProgress = 0;
            this.connectionsInProgress.add(newCable);
        }
    }

    void removeRandomConnection() {
        if (this.cables.size() > 0) {
            int cableIndex = floor(random(this.cables.size()));
            Cable cable = this.cables.get(cableIndex);

            // Add to disconnection list
            cable.disconnectionProgress = 0;
            this.disconnectionsInProgress.add(new DisconnectionProgress(cable, cableIndex));
        }
    }

    void updateConnectionAnimations(float deltaTime) {
        // Update connecting cables
        for (int i = this.connectionsInProgress.size() - 1; i >= 0; i--) {
            Cable cable = this.connectionsInProgress.get(i);

            // Update animation progress
            if (cable.updateConnectionProgress(deltaTime)) {
                // Animation complete, add to regular cables
                this.cables.add(cable);
                this.connectionsInProgress.remove(i);
            }
        }

        // Update disconnecting cables
        for (int i = this.disconnectionsInProgress.size() - 1; i >= 0; i--) {
            DisconnectionProgress dp = this.disconnectionsInProgress.get(i);
            Cable cable = dp.cable;

            // Update animation progress
            if (cable.updateDisconnectionProgress(deltaTime)) {
                // Animation complete, remove cable
                this.cables.remove(dp.index);
                this.disconnectionsInProgress.remove(i);

                // Unlock the jacks for future connections
                cable.startJack.disconnect();
                cable.endJack.disconnect();
            }
        }
    }

    void draw() {
        background(this.config.backgroundColor);

        // Manage automatic connections/disconnections
        this.manageConnections();

        // Update physics simulation
        this.updatePhysics();

        // Draw cables behind jacks and connectors
        for (Cable cable : this.cables) {
            cable.draw();
        }

        // Draw in-progress connections
        for (Cable cable : this.connectionsInProgress) {
            cable.drawConnection();
        }

        // Draw in-progress disconnections
        for (DisconnectionProgress dp : this.disconnectionsInProgress) {
            dp.cable.drawDisconnection();
        }

        // Draw jacks (connection points)
        for (Jack jack : this.jacks) {
            jack.draw();
        }

        // Draw cable connectors
        this.drawConnectors();
    }

    void drawConnectors() {
        // Draw connectors for regular cables
        for (Cable cable : this.cables) {
            cable.drawConnectors();
        }

        // Draw connectors for in-progress connections
        for (Cable cable : this.connectionsInProgress) {
            float progress = cable.connectionProgress;
            if (progress > 0.1) {
                // Only draw the start connector
                CablePoint startPoint = cable.points.get(0);
                cable.drawConnector(startPoint);
            }
        }

        // Draw connectors for in-progress disconnections
        for (DisconnectionProgress dp : this.disconnectionsInProgress) {
            Cable cable = dp.cable;
            float progress = cable.disconnectionProgress;
            if (progress < 0.9) {
                // Only draw the end connector
                CablePoint endPoint = cable.points.get(cable.points.size() - 1);
                cable.drawConnector(endPoint);
            }
        }
    }

    void windowResized() {
        // This will be called by the main sketch when the window is resized
        this.canvasWidth = width;
        this.canvasHeight = height;
        this.resetSimulation();
    }
}

// Helper class to store disconnection information
class DisconnectionProgress {
    Cable cable;
    int index;
    
    DisconnectionProgress(Cable cable, int index) {
        this.cable = cable;
        this.index = index;
    }
}
