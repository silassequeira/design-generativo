let reconstructionSystem;

function preload() {
    // Create the reconstruction system
    reconstructionSystem = new ReconstructionSystem();

    // Preload the image
    reconstructionSystem.preloadImage('blood-elevator-rs.jpg');
}

function setup() {
    // Set pixelDensity to 1 for better performance
    pixelDensity(1);

    // Create canvas
    const canvasWidth = windowWidth;
    const canvasHeight = windowHeight;
    let canvas = createCanvas(canvasWidth, canvasHeight);
    canvas.parent('canvas-container');

    // Initialize the reconstruction system
    reconstructionSystem.initialize(canvasWidth, canvasHeight);

    // Set frameRate for smoother animation
    frameRate(16);
}

function draw() {
    // Update the reconstruction system
    reconstructionSystem.update();

    // Draw the reconstruction system
    reconstructionSystem.draw();
}

function keyPressed() {
    reconstructionSystem.handleKeyPressed(key);
}

function windowResized() {
    // Resize canvas
    resizeCanvas(windowWidth, windowHeight);

    // Handle window resizing in the reconstruction system
    reconstructionSystem.handleWindowResized(windowWidth, windowHeight);
}