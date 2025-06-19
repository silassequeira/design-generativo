class ImageCableVisualizer {
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
    
    int lastFrameTime;

    ImageCableVisualizer() {
      
        this.config = new Config();
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
        createConnectionPoints();
        loadImagesFromFolder();
    }
    
    void createConnectionPoints() {
        int numPointsPerEdge = 10;
        
        // Create points on each edge of the screen
        createEdgePoints(0, 0, width, 0, numPointsPerEdge);              // Top edge
        createEdgePoints(width, 0, width, height, numPointsPerEdge);     // Right edge
        createEdgePoints(width, height, 0, height, numPointsPerEdge);    // Bottom edge
        createEdgePoints(0, height, 0, 0, numPointsPerEdge);            // Left edge
    }
    
    void createEdgePoints(float startX, float startY, float endX, float endY, int count) {
        for (int i = 0; i < count; i++) {
            float t = (float)i / (count - 1);
            float x = lerp(startX, endX, t);
            float y = lerp(startY, endY, t);
            connectionPoints.add(new PVector(x, y));
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
        
        boolean imagesLoaded = false;
        
        // Load each image file
        for (String filename : filenames) {
            if (isImageFile(filename)) {
                PImage img = loadImage(filename);
                if (img == null) continue;
                
                // Resize image if needed
                resizeImageIfNeeded(img);
                
                // Create a floating image at a random position
                float x = random(img.width/2, width - img.width/2);
                float y = random(img.height/2, height - img.height/2);
                float scale = random(0.8, 1.5);
                images.add(new FloatingImage(img, x, y, false, scale));
                imagesLoaded = true;
            }
        }
        
        // If no images were found, create placeholders
        if (!imagesLoaded) {
            createPlaceholderImages();
        }
    }
    
    boolean isImageFile(String filename) {
        String lowercaseFilename = filename.toLowerCase();
        return lowercaseFilename.endsWith(".jpg") || 
               lowercaseFilename.endsWith(".jpeg") || 
               lowercaseFilename.endsWith(".png") || 
               lowercaseFilename.endsWith(".gif");
    }
    
    void resizeImageIfNeeded(PImage img) {
        float maxDimension = 150;
        if (img.width > maxDimension || img.height > maxDimension) {
            float scaleFactor = maxDimension / max(img.width, img.height);
            img.resize((int)(img.width * scaleFactor), (int)(img.height * scaleFactor));
        }
    }
    
    void createPlaceholderImages() {
        println("No images found, creating placeholders");
        for (int i = 0; i < 5; i++) {
            PImage img = createColoredPlaceholder(100, 100, color(random(255), random(255), random(255)));
            float x = random(img.width/2, width - img.width/2);
            float y = random(img.height/2, height - img.height/2);
            images.add(new FloatingImage(img, x, y, false, random(0.8, 1.5)));
        }
    }
    
    PImage createColoredPlaceholder(int w, int h, color c) {
        PImage img = createImage(w, h, ARGB);
        img.loadPixels();
        for (int i = 0; i < img.pixels.length; i++) {
            img.pixels[i] = c;
        }
        img.updatePixels();
        return img;
    }

    void draw() {
        background(config.backgroundColor);
        
        // Calculate deltaTime and update animation time
        int currentTime = millis();
        float deltaTime = (currentTime - this.lastFrameTime);
        this.lastFrameTime = currentTime;
        this.globalAnimationTime += deltaTime;
        
        // Update dynamic physics parameters
        updateDynamicPhysics();
        
        // Update all objects
        updateImages();
        updateCables();
        
        // Manage connections/disconnections
        manageConnections(deltaTime);
        
        // Draw everything
        drawVisualization();
    }
    
    void updateDynamicPhysics() {
        // Vary gravity and tension over time for more organic movement
        float[] gravityRange = this.config.autoGravityRange;
        float[] tensionRange = this.config.autoTensionRange;
        this.config.gravity = map(sin(this.globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
        this.config.tension = floor(map(sin(this.globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]));
    }
    
    void updateImages() {
        // Update all floating images
        for (FloatingImage img : images) {
            img.update();
        }
    }
    
    void updateCables() {
        // Update all existing cables
        for (Cable cable : cables) {
            cable.updatePhysics();
        }
    }
    
    void manageConnections(float deltaTime) {
        // Update existing animations
        updateConnectionAnimations(deltaTime);
        
        // Check if it's time for a new connection/disconnection event
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
    
    void updateConnectionAnimations(float deltaTime) {
        // Update connecting cables
        for (int i = connectionsInProgress.size() - 1; i >= 0; i--) {
            Cable cable = connectionsInProgress.get(i);
            cable.updatePhysics();

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
            cable.updatePhysics();

            if (cable.updateDisconnectionProgress(deltaTime)) {
                // Animation complete, remove cable
                if (dp.index < cables.size()) {
                    cables.remove(dp.index);
                }
                disconnectionsInProgress.remove(i);
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
    
    void drawVisualization() {
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
