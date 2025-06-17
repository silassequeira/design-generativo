class ImageCableVisualizer {
    // Configuration
    Config config;

    // Images and cables
    ArrayList<FloatingImage> images;
    ArrayList<Cable> cables;
    ArrayList<Cable> connectionsInProgress;
    ArrayList<DisconnectionProgress> disconnectionsInProgress;
    
    // Fixed connection points at screen edges
    ArrayList<PVector> connectionPoints;
    
    // Animation state
    int lastConnectionTime;
    float globalAnimationTime;
    
    // For tracking deltaTime
    int lastFrameTime;

    ImageCableVisualizer() {
        // Create configuration
        this.config = new Config();

        // Initialize collections
        this.images = new ArrayList<FloatingImage>();
        this.cables = new ArrayList<Cable>();
        this.connectionsInProgress = new ArrayList<Cable>();
        this.disconnectionsInProgress = new ArrayList<DisconnectionProgress>();
        this.connectionPoints = new ArrayList<PVector>();
        
        this.globalAnimationTime = 0;
        this.lastConnectionTime = 0;
    }

    void setup() {
        this.lastFrameTime = millis();
        
        // Create connection points at screen edges
        createConnectionPoints();
        
        // Load images from data folder
        loadImagesFromFolder();
    }
    
    void createConnectionPoints() {
        // Create points along the edges of the screen
        int numPointsPerEdge = 10;
        
        // Top edge
        for (int i = 0; i < numPointsPerEdge; i++) {
            connectionPoints.add(new PVector(
                width * ((float)i / (numPointsPerEdge - 1)),
                0
            ));
        }
        
        // Right edge
        for (int i = 0; i < numPointsPerEdge; i++) {
            connectionPoints.add(new PVector(
                width,
                height * ((float)i / (numPointsPerEdge - 1))
            ));
        }
        
        // Bottom edge
        for (int i = 0; i < numPointsPerEdge; i++) {
            connectionPoints.add(new PVector(
                width * (1 - ((float)i / (numPointsPerEdge - 1))),
                height
            ));
        }
        
        // Left edge
        for (int i = 0; i < numPointsPerEdge; i++) {
            connectionPoints.add(new PVector(
                0,
                height * (1 - ((float)i / (numPointsPerEdge - 1)))
            ));
        }
    }

    void loadImagesFromFolder() {
        // Get list of files in the data folder
        java.io.File folder = new java.io.File(dataPath(""));
        String[] filenames = folder.list();
        
        if (filenames == null) {
            println("Error: Could not list files in data folder");
            createPlaceholderImages();
            return;
        }
        
        // Load each image file
        for (String filename : filenames) {
            String lowercaseFilename = filename.toLowerCase();
            if (lowercaseFilename.endsWith(".jpg") || 
                lowercaseFilename.endsWith(".jpeg") || 
                lowercaseFilename.endsWith(".png") || 
                lowercaseFilename.endsWith(".gif")) {
                    
                // Load the image
                PImage img = loadImage(filename);
                if (img == null) continue;
                
                // Resize image if it's too large
                float maxDimension = 150;
                if (img.width > maxDimension || img.height > maxDimension) {
                    float scaleFactor = maxDimension / max(img.width, img.height);
                    img.resize((int)(img.width * scaleFactor), (int)(img.height * scaleFactor));
                }
                
                // Create a floating image at a random position
                float x = random(img.width/2, width - img.width/2);
                float y = random(img.height/2, height - img.height/2);
                images.add(new FloatingImage(img, x, y));
            }
        }
        
        // If no images were found, create some placeholder colored rectangles
        if (images.size() == 0) {
            createPlaceholderImages();
        }
    }
    
    void createPlaceholderImages() {
        println("No images found, creating placeholders");
        for (int i = 0; i < 5; i++) {
            PImage img = createImage(100, 100, ARGB);
            img.loadPixels();
            color c = color(random(255), random(255), random(255));
            for (int j = 0; j < img.pixels.length; j++) {
                img.pixels[j] = c;
            }
            img.updatePixels();
            
            float x = random(img.width/2, width - img.width/2);
            float y = random(img.height/2, height - img.height/2);
            images.add(new FloatingImage(img, x, y));
        }
    }

    void update() {
        // Calculate deltaTime (in milliseconds)
        int currentTime = millis();
        float deltaTime = (currentTime - this.lastFrameTime);
        this.lastFrameTime = currentTime;
        
        this.globalAnimationTime += deltaTime;

        // Update all floating images
        for (FloatingImage img : images) {
            img.update();
        }
        
        // Vary gravity and tension over time
        float[] gravityRange = this.config.autoGravityRange;
        float[] tensionRange = this.config.autoTensionRange;
        this.config.gravity = map(sin(this.globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
        this.config.tension = floor(map(sin(this.globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]));

        // Update all existing cables
        for (Cable cable : cables) {
            cable.updatePhysics();
        }
        
        // Update connection animations
        updateConnectionAnimations(deltaTime);
        
        // Check if it's time for a new connection or disconnection
        if (millis() - this.lastConnectionTime > this.config.connectionInterval) {
            this.lastConnectionTime = millis();

            // Either create or remove a connection
            if (random(1) < 0.7 && cables.size() < this.config.cableCount * 2) {
                createNewConnection();
            } else if (cables.size() > 0) {
                removeRandomConnection();
            } else {
                createNewConnection();
            }
        }
    }
    
    void createNewConnection() {
        if (images.size() == 0) return;
        
        // Choose a random connection point from the edge
        int pointIndex = floor(random(connectionPoints.size()));
        PVector startPoint = connectionPoints.get(pointIndex);
        
        // Choose a random image to connect to
        FloatingImage targetImage = images.get(floor(random(images.size())));
        
        // Create the new connection
        Cable newCable = new Cable(startPoint.x, startPoint.y, targetImage, config);
        newCable.connectionProgress = 0;
        connectionsInProgress.add(newCable);
    }
    
    void removeRandomConnection() {
        if (cables.size() > 0) {
            int cableIndex = floor(random(cables.size()));
            Cable cable = cables.get(cableIndex);
            
            // Add to disconnection list
            cable.disconnectionProgress = 0;
            disconnectionsInProgress.add(new DisconnectionProgress(cable, cableIndex));
        }
    }
    
    void updateConnectionAnimations(float deltaTime) {
        // Update connecting cables
        for (int i = connectionsInProgress.size() - 1; i >= 0; i--) {
            Cable cable = connectionsInProgress.get(i);
            
            // Update physics to follow moving image
            cable.updatePhysics();

            // Update animation progress
            if (cable.updateConnectionProgress(deltaTime)) {
                // Animation complete, add to regular cables
                cables.add(cable);
                connectionsInProgress.remove(i);
            }
        }

        // Update disconnecting cables
        for (int i = disconnectionsInProgress.size() - 1; i >= 0; i--) {
            DisconnectionProgress dp = disconnectionsInProgress.get(i);
            Cable cable = dp.cable;
            
            // Update physics to follow moving image
            cable.updatePhysics();

            // Update animation progress
            if (cable.updateDisconnectionProgress(deltaTime)) {
                // Animation complete, remove cable
                if (dp.index < cables.size()) {
                    cables.remove(dp.index);
                }
                disconnectionsInProgress.remove(i);
            }
        }
    }

    void draw() {
        background(config.backgroundColor);
        
        // Update everything
        update();
        
        // Draw cables behind images
        for (Cable cable : cables) {
            cable.draw();
        }
        
        // Draw connecting cables
        for (Cable cable : connectionsInProgress) {
            cable.drawConnection();
        }
        
        // Draw disconnecting cables
        for (DisconnectionProgress dp : disconnectionsInProgress) {
            dp.cable.drawDisconnection();
        }
        
        // Draw all floating images
        for (FloatingImage img : images) {
            img.draw();
        }
    }
}
