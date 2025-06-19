class SynthVisualizer {
    Config config;
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
        if (this.cables.size() > 20) {
            this.cables = new ArrayList<Cable>(this.cables.subList(0, 20));
        }
    }

    void resetSimulation() {
        this.jacks = new ArrayList<Jack>();
        this.cables = new ArrayList<Cable>();
        this.connectionsInProgress = new ArrayList<Cable>();
        this.disconnectionsInProgress = new ArrayList<DisconnectionProgress>();

        // Create jacks and cables
        createJacks();
        createCables();
    }

    void createJacks() {
        int jackId = 0;

        // Calculate dynamic margins based on canvas size
        float horizontalMargin = this.canvasWidth * 0.12;
        float verticalMargin = this.canvasHeight * 0.18;

        // Calculate usable area
        float usableWidth = this.canvasWidth - (horizontalMargin * 2);
        float usableHeight = this.canvasHeight - (verticalMargin * 2);

        // Create top row of jacks
        createJackRow(jackId, 8, horizontalMargin, usableWidth, verticalMargin, 0);
        jackId += 8;
        
        // Create bottom row of jacks
        createJackRow(jackId, 8 , horizontalMargin, usableWidth, this.canvasHeight - verticalMargin, 0);
        jackId += 8;
        
        // Create middle row of jacks
        createJackRow(jackId, 8 , horizontalMargin, usableWidth, this.canvasHeight / 2, 0);
        jackId += 8;
        
        // Create left column of jacks
        createJackColumn(jackId, 3, horizontalMargin, verticalMargin, usableHeight);
        jackId += 3;
        
        // Create right column of jacks
        createJackColumn(jackId, 3 , this.canvasWidth - horizontalMargin, verticalMargin, usableHeight);
    }
    
    void createJackRow(int startId, int count, float startX, float width, float y, float yVariation) {
        for (int i = 0; i < count; i++) {
            float x = startX + (width / (count - 1)) * i;
            float finalY = y + (yVariation > 0 ? random(-yVariation, yVariation) : 0);
            this.jacks.add(new Jack(x, finalY, startId + i, this.config));
        }
    }
    
    void createJackColumn(int startId, int count, float x, float startY, float height) {
        for (int i = 0; i < count; i++) {
            float y = startY + (height / (count + 1)) * (i + 1);
            this.jacks.add(new Jack(x, y, startId + i, this.config));
        }
    }

    void createCables() {
        for (int i = 0; i < this.config.cableCount; i++) {
            Jack startJack = getRandomUnconnectedJack();
            Jack endJack = getRandomUnconnectedJack(startJack);
            
            if (startJack != null && endJack != null) {
                this.cables.add(new Cable(startJack, endJack, this.config));
            }
        }
    }
    
    Jack getRandomUnconnectedJack() {
        // Create a copy of all unconnected jacks
        ArrayList<Jack> unconnectedJacks = new ArrayList<Jack>();
        for (Jack jack : this.jacks) {
            if (!jack.connected) {
                unconnectedJacks.add(jack);
            }
        }
        
        if (unconnectedJacks.size() == 0) return null;
        
        // Return a random unconnected jack
        return unconnectedJacks.get(floor(random(unconnectedJacks.size())));
    }
    
    Jack getRandomUnconnectedJack(Jack excludeJack) {
        // Create a copy of all unconnected jacks except the excluded one
        ArrayList<Jack> unconnectedJacks = new ArrayList<Jack>();
        for (Jack jack : this.jacks) {
            if (!jack.connected && jack != excludeJack) {
                unconnectedJacks.add(jack);
            }
        }
        
        if (unconnectedJacks.size() == 0) return null;
        
        // Return a random unconnected jack
        return unconnectedJacks.get(floor(random(unconnectedJacks.size())));
    }

    void draw() {
        background(this.config.backgroundColor);

        // Calculate deltaTime
        int currentTime = millis();
        float deltaTime = (currentTime - this.lastFrameTime);
        this.lastFrameTime = currentTime;
        this.globalAnimationTime += deltaTime;

        // Update physics parameters for organic movement
        updateDynamicPhysics();
        
        // Manage connections/disconnections
        manageConnections(deltaTime);
        
        // Update physics for all cables
        updateAllPhysics();
        
        // Draw the visualization
        drawVisualization();
    }
    
    void updateDynamicPhysics() {
        float[] gravityRange = this.config.autoGravityRange;
        float[] tensionRange = this.config.autoTensionRange;
        this.config.gravity = map(sin(this.globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
        this.config.tension = floor(map(sin(this.globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]));
    }

    void manageConnections(float deltaTime) {
      
        updateConnectionAnimations(deltaTime);
        
        // Check if it's time for a new connection/disconnection event
        if (millis() - this.lastConnectionTime > this.config.connectionInterval) {
            this.lastConnectionTime = millis();

            // Randomly decide to create or remove a connection
            if (random(1) < 0.8 && this.cables.size() < this.config.cableCount) {
                createNewConnection();
            } else if (this.cables.size() > 0) {
                removeRandomConnection();
            } else {
                createNewConnection();
            }
        }
    }
            // Update connecting cables & animation progress
    void updateConnectionAnimations(float deltaTime) {
        for (int i = this.connectionsInProgress.size() - 1; i >= 0; i--) {
            Cable cable = this.connectionsInProgress.get(i);

            if (cable.updateConnectionProgress(deltaTime)) {
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

    void createNewConnection() {
        ArrayList<Jack> unconnectedJacks = new ArrayList<Jack>();
        for (Jack jack : this.jacks) {
            if (!jack.connected) {
                unconnectedJacks.add(jack);
            }
        }

        if (unconnectedJacks.size() >= 2) {
            int startIndex = floor(random(unconnectedJacks.size()));
            Jack startJack = unconnectedJacks.get(startIndex);

            // Find jacks that are within a reasonable distance
            float maxConnectionDistance = this.canvasWidth / 2;
            ArrayList<Jack> possibleTargets = new ArrayList<Jack>();

            for (int i = 0; i < unconnectedJacks.size(); i++) {
                if (i == startIndex) continue;

                Jack jack = unconnectedJacks.get(i);
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

    void updateAllPhysics() {
        // Apply physics to each cable
        for (Cable cable : this.cables) {
            cable.updatePhysics();
        }
    }
    
    void drawVisualization() {
      
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

        drawAllConnectors();
    }

    void drawAllConnectors() {
      
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
}
