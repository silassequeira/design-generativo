class SynthVisualizer {
    constructor() {
        // Create configuration
        this.config = new Config();

        // Main variables
        this.jacks = [];
        this.cables = [];
        this.canvasWidth = 0;
        this.canvasHeight = 0;

        // Animation state
        this.lastConnectionTime = 0;
        this.connectionsInProgress = [];
        this.disconnectionsInProgress = [];
        this.globalAnimationTime = 0;
    }

    setup() {
        // Create canvas that fills the window
        this.canvasWidth = windowWidth;
        this.canvasHeight = windowHeight;
        let canvas = createCanvas(this.canvasWidth, this.canvasHeight);
        canvas.parent('canvas-container');

        // Initialize the visualization
        this.resetSimulation();

        // Start with fewer cables so we can see them being created
        this.cables = this.cables.slice(0, 3);
    }

    resetSimulation() {
        this.jacks = [];
        this.cables = [];
        this.connectionsInProgress = [];
        this.disconnectionsInProgress = [];

        // Create fixed connection points (like synthesizer jacks)
        this.jacks = Jack.createJacks(this.canvasWidth, this.canvasHeight, this.config);

        // Create initial cables between random points
        this.createCables();
    }

    createCables() {
        // Create cables between random jacks
        for (let i = 0; i < this.config.cableCount; i++) {
            let startIndex = floor(random(this.jacks.length));
            let endIndex;
            do {
                endIndex = floor(random(this.jacks.length));
            } while (startIndex === endIndex);

            const startJack = this.jacks[startIndex];
            const endJack = this.jacks[endIndex];

            this.cables.push(new Cable(startJack, endJack, this.config));
        }
    }

    updatePhysics() {
        // Apply physics to each cable
        this.cables.forEach(cable => cable.updatePhysics());
    }

    manageConnections() {
        this.globalAnimationTime += deltaTime;

        // Vary gravity and tension over time for more organic movement
        const gravityRange = this.config.autoGravityRange;
        const tensionRange = this.config.autoTensionRange;
        this.config.gravity = map(sin(this.globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
        this.config.tension = map(sin(this.globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]);

        // Update connection animations in progress
        this.updateConnectionAnimations();

        // Check if it's time to make a new connection or disconnection
        if (millis() - this.lastConnectionTime > this.config.connectionInterval) {
            this.lastConnectionTime = millis();

            // Randomly decide to create or remove a connection
            if (random() < 0.6 && this.cables.length < this.config.cableCount) {
                // Create a new connection
                this.createNewConnection();
            } else if (this.cables.length > 0) {
                // Remove a connection
                this.removeRandomConnection();
            } else {
                this.createNewConnection();
            }
        }
    }

    createNewConnection() {
        // Find unconnected jacks
        const unconnectedJacks = this.jacks.filter(jack => !jack.connected);

        if (unconnectedJacks.length >= 2) {
            const startIndex = floor(random(unconnectedJacks.length));
            const startJack = unconnectedJacks[startIndex];

            // Find jacks that are within a reasonable connection distance
            const maxConnectionDistance = this.canvasWidth / 2;  // Limit how far cables can stretch

            const possibleTargets = unconnectedJacks.filter((jack, index) => {
                if (index === startIndex) return false;  // Can't connect to self

                // Calculate distance between jacks
                const distance = dist(startJack.x, startJack.y, jack.x, jack.y);
                return distance < maxConnectionDistance;
            });

            // If no valid targets found, exit
            if (possibleTargets.length === 0) return;

            // Choose a random end jack from valid targets
            const endJack = possibleTargets[floor(random(possibleTargets.length))];

            // Create new connection and add to in-progress list
            const newCable = new Cable(startJack, endJack, this.config);
            newCable.connectionProgress = 0;
            this.connectionsInProgress.push(newCable);
        }
    }

    removeRandomConnection() {
        if (this.cables.length > 0) {
            const cableIndex = floor(random(this.cables.length));
            const cable = this.cables[cableIndex];

            // Add to disconnection list
            cable.disconnectionProgress = 0;
            this.disconnectionsInProgress.push({ cable, index: cableIndex });
        }
    }

    updateConnectionAnimations() {
        // Update connecting cables
        for (let i = this.connectionsInProgress.length - 1; i >= 0; i--) {
            const cable = this.connectionsInProgress[i];

            // Update animation progress
            if (cable.updateConnectionProgress(deltaTime)) {
                // Animation complete, add to regular cables
                this.cables.push(cable);
                this.connectionsInProgress.splice(i, 1);
            }
        }

        // Update disconnecting cables
        for (let i = this.disconnectionsInProgress.length - 1; i >= 0; i--) {
            const { cable, index } = this.disconnectionsInProgress[i];

            // Update animation progress
            if (cable.updateDisconnectionProgress(deltaTime)) {
                // Animation complete, remove cable
                this.cables.splice(index, 1);
                this.disconnectionsInProgress.splice(i, 1);

                // Unlock the jacks for future connections
                cable.startJack.disconnect();
                cable.endJack.disconnect();
            }
        }
    }

    draw() {
        background(this.config.backgroundColor);

        // Manage automatic connections/disconnections
        this.manageConnections();

        // Update physics simulation
        this.updatePhysics();

        // Draw cables behind jacks and connectors
        this.cables.forEach(cable => cable.draw());

        // Draw in-progress connections
        this.connectionsInProgress.forEach(cable => cable.drawConnection());

        // Draw in-progress disconnections
        this.disconnectionsInProgress.forEach(({ cable }) => cable.drawDisconnection());

        // Draw jacks (connection points)
        this.jacks.forEach(jack => jack.draw());

        // Draw cable connectors
        this.drawConnectors();
    }

    drawConnectors() {
        // Draw connectors for regular cables
        this.cables.forEach(cable => cable.drawConnectors());

        // Draw connectors for in-progress connections
        this.connectionsInProgress.forEach(cable => {
            const progress = cable.connectionProgress;
            if (progress > 0.1) {
                // Only draw the start connector
                const startPoint = cable.points[0];
                cable.drawConnector(startPoint);
            }
        });

        // Draw connectors for in-progress disconnections
        this.disconnectionsInProgress.forEach(({ cable }) => {
            const progress = cable.disconnectionProgress;
            if (progress < 0.9) {
                // Only draw the end connector
                const endPoint = cable.points[cable.points.length - 1];
                cable.drawConnector(endPoint);
            }
        });
    }

    windowResized() {
        this.canvasWidth = windowWidth;
        this.canvasHeight = windowHeight;
        resizeCanvas(this.canvasWidth, this.canvasHeight);
        this.resetSimulation();
    }
}