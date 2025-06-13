class ReconstructionSystem {
    constructor() {
        this.config = new Config();
        this.imageAnalyzer = new ImageAnalyzer(this.config);
        this.jackManager = new JackManager(this.config, this.imageAnalyzer);
        this.cableGenerator = new CableGenerator(this.config, this.imageAnalyzer, this.jackManager);

        this.canvasWidth = 0;
        this.canvasHeight = 0;
        this.initialized = false;
    }

    preloadImage(path) {
        this.imageAnalyzer.preloadImage(
            path,
            () => { console.log("Image loaded successfully"); },
            () => { console.error("Failed to load image"); }
        );
    }

    initialize(canvasWidth, canvasHeight) {
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;

        if (!this.imageAnalyzer.imageLoaded) {
            console.error("Cannot initialize - image not loaded");
            return false;
        }

        // Resize image to fill the canvas completely
        this.imageAnalyzer.resizeImage(canvasWidth, canvasHeight);

        // Analyze the source image
        this.imageAnalyzer.analyzeImage();

        // Generate color clusters from the image
        this.imageAnalyzer.generateColorClusters();

        // Reset simulation
        this.resetSimulation();

        this.initialized = true;
        return true;
    }

    resetSimulation() {
        if (!this.imageAnalyzer.imageLoaded) return;

        console.log("Resetting simulation...");

        // Reset components
        this.jackManager.jacks = [];
        this.cableGenerator.reset();

        // Create jacks based on image features
        this.jackManager.createJacksFromImage();

        // Plan all cables but don't add them immediately for progressive rendering
        this.cableGenerator.planCablesFromImage();

        console.log(`Created ${this.jackManager.jacks.length} jacks and planned ${this.cableGenerator.pendingCables.length} cables`);
    }

    update() {
        if (!this.initialized) return;

        // Progressive rendering - add cables gradually
        this.cableGenerator.addCablesProgressively();
    }

    draw() {
        if (!this.initialized) {
            // Show loading message
            background(0);
            fill(255);
            textSize(20);
            textAlign(CENTER, CENTER);
            text("Loading image...", width / 2, height / 2);
            return;
        }

        background(this.config.backgroundColor);

        // Optionally show the original image in the background
        if (this.config.showOriginalImage && this.imageAnalyzer.sourceImage) {
            push();
            tint(255, 40); // Show with low opacity
            image(this.imageAnalyzer.sourceImage, 0, 0);
            noTint();
            pop();
        }

        // Draw cables
        this.cableGenerator.drawCables();

        // Draw jacks
        this.jackManager.drawJacks();

        // Display progress
        if (this.cableGenerator.pendingCables.length > 0) {
            let progress = this.cableGenerator.getProgress();
            fill(255);
            noStroke();
            textSize(14);
            textAlign(LEFT, TOP);
            text(`Progress: ${floor(progress)}%`, 10, 10);
        }
    }

    handleKeyPressed(key) {
        switch (key) {
            case 'r':
            case 'R':
                this.resetSimulation();
                break;

            case 'j':
            case 'J':
                this.config.toggle('showJacks');
                break;

            case 'i':
            case 'I':
                this.config.toggle('showOriginalImage');
                break;

            case 'p':
            case 'P':
                this.config.toggle('progressiveRendering');
                if (!this.config.progressiveRendering) {
                    // Add all pending cables immediately
                    this.cableGenerator.addAllCablesImmediately();
                }
                break;

            case '+':
            case '=':
                this.config.cableCount += 100;
                this.resetSimulation();
                break;

            case '-':
            case '_':
                this.config.cableCount = max(50, this.config.cableCount - 100);
                this.resetSimulation();
                break;
        }
    }

    handleWindowResized(newWidth, newHeight) {
        this.canvasWidth = newWidth;
        this.canvasHeight = newHeight;

        if (this.imageAnalyzer.sourceImage) {
            // Resize image to fill the canvas completely
            this.imageAnalyzer.resizeImage(this.canvasWidth, this.canvasHeight);

            // Re-analyze image and reset simulation
            this.imageAnalyzer.analyzeImage();
            this.imageAnalyzer.generateColorClusters();
            this.resetSimulation();
        }
    }
}