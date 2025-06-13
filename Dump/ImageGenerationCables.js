// Image Reconstruction with Progressive Taut Cables
// Recreates an image using straight colored lines with a gradual build-up

// Configuration
let config = {
    // Visualization settings
    cableCount: 3000,         // Target number of cables (much higher for detail)
    cablesPerFrame: 3,        // How many cables to add each frame for progressive build-up
    cableThickness: 2,      // Thinner lines for finer detail
    jackRadius: 2,            // Small jacks
    showJacks: false,         // Don't show connection points by default
    backgroundColor: [20, 20, 30],
    alpha: 140,               // Alpha value for lines (transparency)

    // Image analysis settings
    edgeThreshold: 70,        // Threshold for edge detection
    jackDensity: 0.7,         // Higher density for better coverage
    maxJacks: 1000,            // More jacks for detailed reproduction
    imageInfluence: 0.9,      // Stronger image influence
    colorSamples: 17,          // More color samples for better color representation
    minCableLength: 30,       // Shorter minimum cables for more detail
    maxCableLength: 300,      // Shorter max length to avoid cross-image cables
    edgePreference: 1.8,      // How much to prefer edge-following paths
    colorPalette: 17,         // Number of color clusters to use

    // Performance settings
    maxConnectionsPerJack: 5, // Limit connections per point to avoid clutter
    progressiveRendering: true, // Enable progressive building of the image
    showOriginalImage: false   // Toggle to show original image
};

// Main variables
let points = [];
let cables = [];
let pendingCables = [];  // Cables waiting to be added progressively
let colorClusters = [];  // Store color clusters for the image
let canvasWidth, canvasHeight;
let sourceImage;
let edgeMap;
let brightnessMap;
let imageLoaded = false;
let buildProgress = 0;   // Progress counter for animation

function preload() {
    // Load your source image
    sourceImage = loadImage('blood-elevator-rs.jpg',
        // Success callback
        () => { imageLoaded = true; },
        // Error callback
        () => { console.error("Failed to load image"); }
    );
}

function setup() {
    // Set pixelDensity to 1 for better performance
    pixelDensity(1);

    if (!imageLoaded) {
        console.error("Image not loaded properly");
        // Create a default canvas
        canvasWidth = windowWidth;
        canvasHeight = windowHeight;
        createCanvas(canvasWidth, canvasHeight);
        return;
    }

    // Always create a canvas that fills the window
    canvasWidth = windowWidth;
    canvasHeight = windowHeight;
    let canvas = createCanvas(canvasWidth, canvasHeight);
    canvas.parent('canvas-container');

    // Resize image to fill the canvas completely
    sourceImage.resize(canvasWidth, canvasHeight);

    // Analyze the source image
    analyzeImage();

    // Generate color clusters from the image
    generateColorClusters();

    // Initialize the visualization
    resetSimulation();

    // Set frameRate for smoother animation
    frameRate(16);
}

function analyzeImage() {
    console.log("Analyzing image...");

    // Create the edge and brightness maps
    edgeMap = createGraphics(sourceImage.width, sourceImage.height);
    brightnessMap = createGraphics(sourceImage.width, sourceImage.height);

    // Set willReadFrequently attribute for better performance
    edgeMap.drawingContext.canvas.willReadFrequently = true;
    brightnessMap.drawingContext.canvas.willReadFrequently = true;

    // Draw the source image to both graphics buffers
    edgeMap.image(sourceImage, 0, 0);
    brightnessMap.image(sourceImage, 0, 0);

    // Process the brightness map
    brightnessMap.loadPixels();
    for (let i = 0; i < brightnessMap.pixels.length; i += 4) {
        // Calculate brightness
        let r = brightnessMap.pixels[i];
        let g = brightnessMap.pixels[i + 1];
        let b = brightnessMap.pixels[i + 2];
        let brightness = (r + g + b) / 3;

        // Set all channels to brightness value for easier reading later
        brightnessMap.pixels[i] = brightness;
        brightnessMap.pixels[i + 1] = brightness;
        brightnessMap.pixels[i + 2] = brightness;
    }
    brightnessMap.updatePixels();

    // Process the edge map - use a more sophisticated edge detection
    edgeMap.filter(GRAY);

    // Create a temporary graphics buffer for edge detection
    let edgeTemp = createGraphics(edgeMap.width, edgeMap.height);
    edgeTemp.image(edgeMap, 0, 0);

    // Apply more sophisticated edge detection
    edgeMap.loadPixels();
    edgeTemp.loadPixels();

    // Simple Sobel-like edge detection
    for (let x = 1; x < edgeMap.width - 1; x++) {
        for (let y = 1; y < edgeMap.height - 1; y++) {
            // Get surrounding pixels
            let pixNW = brightness(edgeTemp.get(x - 1, y - 1));
            let pixN = brightness(edgeTemp.get(x, y - 1));
            let pixNE = brightness(edgeTemp.get(x + 1, y - 1));
            let pixW = brightness(edgeTemp.get(x - 1, y));
            let pixE = brightness(edgeTemp.get(x + 1, y));
            let pixSW = brightness(edgeTemp.get(x - 1, y + 1));
            let pixS = brightness(edgeTemp.get(x, y + 1));
            let pixSE = brightness(edgeTemp.get(x + 1, y + 1));

            // Horizontal and vertical gradient approximations
            let pixH = (pixNW + pixW + pixSW) - (pixNE + pixE + pixSE);
            let pixV = (pixNW + pixN + pixNE) - (pixSW + pixS + pixSE);

            // Gradient magnitude
            let edgeStrength = sqrt(pixH * pixH + pixV * pixV);

            // Apply threshold
            let edgePixel = edgeStrength > config.edgeThreshold ? 255 : 0;

            // Set pixel in edge map
            let idx = 4 * (y * edgeMap.width + x);
            edgeMap.pixels[idx] = edgePixel;
            edgeMap.pixels[idx + 1] = edgePixel;
            edgeMap.pixels[idx + 2] = edgePixel;
        }
    }

    edgeMap.updatePixels();
    edgeTemp.remove(); // Clean up temporary buffer

    console.log("Image analysis complete.");
}

function generateColorClusters() {
    console.log("Generating color clusters...");

    // Sample colors from the image
    let sampleCount = 2000; // Number of random sample points
    let colorSamples = [];

    // Take random samples from the image
    for (let i = 0; i < sampleCount; i++) {
        let x = floor(random(sourceImage.width));
        let y = floor(random(sourceImage.height));
        let c = sourceImage.get(x, y);
        colorSamples.push({
            r: red(c),
            g: green(c),
            b: blue(c)
        });
    }

    // Simple k-means clustering
    let k = config.colorPalette; // Number of clusters
    let centroids = [];

    // Initialize random centroids from the samples
    for (let i = 0; i < k; i++) {
        let randomIndex = floor(random(colorSamples.length));
        centroids.push({
            r: colorSamples[randomIndex].r,
            g: colorSamples[randomIndex].g,
            b: colorSamples[randomIndex].b
        });
    }

    // Run k-means for a fixed number of iterations
    let iterations = 5;
    for (let iter = 0; iter < iterations; iter++) {
        // Assign each sample to the nearest centroid
        let clusters = new Array(k).fill().map(() => []);

        for (let i = 0; i < colorSamples.length; i++) {
            let sample = colorSamples[i];
            let minDist = Infinity;
            let clusterIndex = 0;

            for (let j = 0; j < k; j++) {
                let centroid = centroids[j];
                let dist = colorDistance(sample, centroid);
                if (dist < minDist) {
                    minDist = dist;
                    clusterIndex = j;
                }
            }

            clusters[clusterIndex].push(sample);
        }

        // Update centroids
        for (let i = 0; i < k; i++) {
            if (clusters[i].length > 0) {
                let sumR = 0, sumG = 0, sumB = 0;
                for (let j = 0; j < clusters[i].length; j++) {
                    sumR += clusters[i][j].r;
                    sumG += clusters[i][j].g;
                    sumB += clusters[i][j].b;
                }

                centroids[i] = {
                    r: sumR / clusters[i].length,
                    g: sumG / clusters[i].length,
                    b: sumB / clusters[i].length
                };
            }
        }
    }

    // Save the clusters for later use
    colorClusters = centroids.map(c => color(c.r, c.g, c.b, config.alpha));

    console.log("Generated", colorClusters.length, "color clusters");
}

function colorDistance(color1, color2) {
    // Simple Euclidean distance in RGB space
    return sqrt(
        sq(color1.r - color2.r) +
        sq(color1.g - color2.g) +
        sq(color1.b - color2.b)
    );
}

function resetSimulation() {
    points = [];
    cables = [];
    pendingCables = [];
    buildProgress = 0;

    if (!imageLoaded) return;

    console.log("Creating jacks and planning cables...");

    // Create jacks based on image features
    createJacksFromImage();

    // Plan all cables but don't add them immediately for progressive rendering
    planCablesFromImage();

    console.log(`Created ${points.length} jacks and planned ${pendingCables.length} cables`);
}

function createJacksFromImage() {
    // Get image dimensions
    const imgWidth = sourceImage.width;
    const imgHeight = sourceImage.height;

    // Calculate grid spacing based on image size
    // For larger images, we can have more points
    const gridSpacing = floor(max(10, min(imgWidth, imgHeight) / 40));
    let jackPositions = [];

    // Create a grid of potential positions
    for (let x = gridSpacing; x < imgWidth; x += gridSpacing) {
        for (let y = gridSpacing; y < imgHeight; y += gridSpacing) {
            jackPositions.push({ x, y });
        }
    }

    // Shuffle the positions
    jackPositions = shuffleArray(jackPositions);

    // Create jacks with strategic placement
    let jacksPlaced = 0;
    let i = 0;

    while (jacksPlaced < config.maxJacks && i < jackPositions.length) {
        let pos = jackPositions[i];
        i++;

        // Sample edge value and brightness
        let edgeValue = red(edgeMap.get(pos.x, pos.y));
        let brightness = red(brightnessMap.get(pos.x, pos.y));

        // Higher probability near edges and in areas with more contrast
        let placementProbability = 0.1; // Base probability

        if (edgeValue > 200) {
            placementProbability += 0.6; // Much higher on edges
        }

        // Prefer areas with high contrast
        const contrast = getLocalContrast(pos.x, pos.y);
        placementProbability += contrast * 0.3;

        // Add probability based on brightness - favor areas with more detail
        if (brightness < 50 || brightness > 200) {
            placementProbability += 0.2; // Higher in very dark or bright areas
        }

        if (random() < placementProbability) {
            // Create the jack with a small random offset for more natural appearance
            points.push({
                x: pos.x + random(-2, 2),
                y: pos.y + random(-2, 2),
                fixed: true,
                isJack: true,
                id: points.length,
                connections: 0
            });

            jacksPlaced++;
        }
    }

    // Add some additional jacks in areas with few jacks
    addSupplementalJacks();
}

function getLocalContrast(x, y) {
    // Sample a small region around the point to determine local contrast
    const radius = 5;
    let samples = [];

    for (let dx = -radius; dx <= radius; dx += 2) {
        for (let dy = -radius; dy <= radius; dy += 2) {
            let sx = constrain(x + dx, 0, sourceImage.width - 1);
            let sy = constrain(y + dy, 0, sourceImage.height - 1);
            samples.push(red(brightnessMap.get(sx, sy)));
        }
    }

    // Calculate standard deviation as a measure of contrast
    const mean = samples.reduce((sum, val) => sum + val, 0) / samples.length;
    const variance = samples.reduce((sum, val) => sum + sq(val - mean), 0) / samples.length;
    return sqrt(variance) / 255; // Normalized contrast value (0-1)
}

function addSupplementalJacks() {
    // First identify areas with low jack density
    const cellSize = 40;
    const rows = ceil(sourceImage.height / cellSize);
    const cols = ceil(sourceImage.width / cellSize);
    let grid = new Array(rows * cols).fill(0);

    // Count jacks in each cell
    for (let p of points) {
        let col = floor(p.x / cellSize);
        let row = floor(p.y / cellSize);
        let index = row * cols + col;
        if (index >= 0 && index < grid.length) {
            grid[index]++;
        }
    }

    // Add jacks in cells with few or no jacks
    const additionalJacks = min(100, config.maxJacks * 0.2);
    let added = 0;

    for (let i = 0; i < grid.length && added < additionalJacks; i++) {
        if (grid[i] < 1) {
            let row = floor(i / cols);
            let col = i % cols;
            let x = col * cellSize + random(5, cellSize - 5);
            let y = row * cellSize + random(5, cellSize - 5);

            // Make sure it's within image bounds
            if (x >= 0 && x < sourceImage.width && y >= 0 && y < sourceImage.height) {
                points.push({
                    x: x,
                    y: y,
                    fixed: true,
                    isJack: true,
                    id: points.length,
                    connections: 0
                });
                added++;
            }
        }
    }
}

function planCablesFromImage() {
    const jackPoints = points.filter(p => p.isJack);
    let attemptedConnections = new Set(); // Track attempted connections

    // Create cables that represent the image
    let cablesPlanned = 0;
    let attempts = 0;
    const maxAttempts = 7000; // More attempts for better quality

    // Keep trying until we have enough planned cables or run out of attempts
    while (cablesPlanned < config.cableCount && attempts < maxAttempts) {
        attempts++;

        // Find jacks that aren't already connected too many times
        let availableJacks = jackPoints.filter(p =>
            p.connections < config.maxConnectionsPerJack
        );

        if (availableJacks.length < 2) break;

        let startJack = availableJacks[floor(random(availableJacks.length))];

        // Find potential target jacks within distance limits
        let potentialTargets = availableJacks.filter(jack => {
            if (jack.id === startJack.id) return false;

            // Calculate distance between jacks
            let distance = dist(startJack.x, startJack.y, jack.x, jack.y);

            // Check if connection already attempted
            let connectionKey = `${min(startJack.id, jack.id)}-${max(startJack.id, jack.id)}`;
            if (attemptedConnections.has(connectionKey)) return false;

            // Add to attempted connections
            attemptedConnections.add(connectionKey);

            // Check distance constraints
            return distance >= config.minCableLength && distance <= config.maxCableLength;
        });

        if (potentialTargets.length === 0) continue;

        // Find a target that best represents the image
        let bestTargetIndex = 0;
        let bestTargetScore = -1;

        for (let i = 0; i < min(potentialTargets.length, 10); i++) {
            let targetJack = potentialTargets[i];
            let score = evaluateConnectionQuality(startJack, targetJack);

            if (score > bestTargetScore) {
                bestTargetScore = score;
                bestTargetIndex = i;
            }
        }

        if (bestTargetScore > 0) {
            let bestTarget = potentialTargets[bestTargetIndex];

            // Create the cable and add to pending list
            let newCable = createCable(startJack, bestTarget);
            pendingCables.push(newCable);

            // Update connection count for both jacks
            startJack.connections++;
            bestTarget.connections++;

            cablesPlanned++;
        }
    }

    // Sort cables by their visual importance
    pendingCables.sort((a, b) => b.importance - a.importance);

    console.log(`Planned ${cablesPlanned} cables after ${attempts} attempts`);
}

function evaluateConnectionQuality(jack1, jack2) {
    // Sample colors and edges along the potential cable path
    const samples = config.colorSamples;
    let colorVariance = 0;
    let edgeFollowing = 0;
    let previousColor = null;
    let sampleColors = [];

    // Get angle of connection
    let angle = atan2(jack2.y - jack1.y, jack2.x - jack1.x);

    // Sample colors and edges along the line
    for (let i = 0; i <= samples; i++) {
        let t = i / samples;
        let x = floor(lerp(jack1.x, jack2.x, t));
        let y = floor(lerp(jack1.y, jack2.y, t));

        // Constrain to image bounds
        x = constrain(x, 0, sourceImage.width - 1);
        y = constrain(y, 0, sourceImage.height - 1);

        // Sample colors
        let imgColor = sourceImage.get(x, y);
        sampleColors.push(imgColor);

        // Check if on edge
        let edgeValue = red(edgeMap.get(x, y));
        if (edgeValue > 200) {
            edgeFollowing++;

            // Extra bonus if the line follows an edge
            if (i > 0 && i < samples) {
                // Check if the edge direction matches the line
                let edgeAngle = getEdgeAngle(x, y);
                let angleDiff = abs(angleDistance(angle, edgeAngle));

                // If line is parallel to edge, give extra points
                if (angleDiff < PI / 4) {
                    edgeFollowing += 0.5;
                }
            }
        }

        if (previousColor !== null) {
            // Calculate color difference from previous sample
            let r1 = red(previousColor);
            let g1 = green(previousColor);
            let b1 = blue(previousColor);

            let r2 = red(imgColor);
            let g2 = green(imgColor);
            let b2 = blue(imgColor);

            // Simple color distance formula
            let colorDiff = sqrt(sq(r2 - r1) + sq(g2 - g1) + sq(b2 - b1));
            colorVariance += colorDiff;
        }

        previousColor = imgColor;
    }

    // Calculate average color variance
    let avgVariance = colorVariance / samples;

    // Calculate edge following score
    let edgeScore = (edgeFollowing / samples) * config.edgePreference * 15;

    // Calculate overall brightness of the line
    let totalBrightness = 0;
    for (let color of sampleColors) {
        totalBrightness += (red(color) + green(color) + blue(color)) / 3;
    }
    let avgBrightness = totalBrightness / sampleColors.length;

    // Score components:
    // 1. Color variance - lower is better (consistent color)
    // 2. Edge following - higher is better
    // 3. Brightness - middle range is better
    let colorConsistencyScore = map(avgVariance, 0, 100, 10, 0);
    let brightnessScore = map(abs(avgBrightness - 128), 0, 128, 5, 0);

    let totalScore = colorConsistencyScore + brightnessScore + edgeScore;

    return totalScore;
}

function getEdgeAngle(x, y) {
    // Simple estimate of edge direction by sampling neighboring pixels
    const radius = 2;
    let edgeX = 0;
    let edgeY = 0;

    for (let dx = -radius; dx <= radius; dx++) {
        for (let dy = -radius; dy <= radius; dy++) {
            if (dx === 0 && dy === 0) continue;

            let sx = constrain(x + dx, 0, edgeMap.width - 1);
            let sy = constrain(y + dy, 0, edgeMap.height - 1);

            let edgeValue = red(edgeMap.get(sx, sy));
            if (edgeValue > 200) {
                edgeX += dx;
                edgeY += dy;
            }
        }
    }

    if (edgeX === 0 && edgeY === 0) return 0;
    return atan2(edgeY, edgeX) + PI / 2; // Rotate 90 degrees to get edge direction
}

function angleDistance(angle1, angle2) {
    // Calculate the smallest angular distance between two angles
    let diff = (angle2 - angle1) % TWO_PI;
    if (diff > PI) diff -= TWO_PI;
    if (diff < -PI) diff += TWO_PI;
    return diff;
}

function createCable(startJack, endJack) {
    // Sample colors along the path to determine best color
    const samples = 8;
    let sampleColors = [];

    // Sample multiple points to get colors
    for (let i = 0; i <= samples; i++) {
        let t = i / samples;
        let x = floor(lerp(startJack.x, endJack.x, t));
        let y = floor(lerp(startJack.y, endJack.y, t));

        // Constrain to image bounds
        x = constrain(x, 0, sourceImage.width - 1);
        y = constrain(y, 0, sourceImage.height - 1);

        // Get image color at this point
        let imgColor = sourceImage.get(x, y);
        sampleColors.push({
            r: red(imgColor),
            g: green(imgColor),
            b: blue(imgColor)
        });
    }

    // Calculate average color
    let r = 0, g = 0, b = 0;
    for (let c of sampleColors) {
        r += c.r;
        g += c.g;
        b += c.b;
    }
    r = r / sampleColors.length;
    g = g / sampleColors.length;
    b = b / sampleColors.length;

    // Find the closest color cluster
    let avgColor = { r, g, b };
    let closestClusterIndex = 0;
    let minDistance = Infinity;

    for (let i = 0; i < colorClusters.length; i++) {
        let cluster = colorClusters[i];
        let dist = colorDistance(avgColor, {
            r: red(cluster),
            g: green(cluster),
            b: blue(cluster)
        });

        if (dist < minDistance) {
            minDistance = dist;
            closestClusterIndex = i;
        }
    }

    // Calculate importance score - used for rendering order
    // Longer lines, lines on edges, and lines with distinct colors are more important
    let length = dist(startJack.x, startJack.y, endJack.x, endJack.y);
    let edgeScore = 0;

    // Check if the line follows edges
    for (let i = 0; i <= samples; i++) {
        let t = i / samples;
        let x = floor(lerp(startJack.x, endJack.x, t));
        let y = floor(lerp(startJack.y, endJack.y, t));
        x = constrain(x, 0, sourceImage.width - 1);
        y = constrain(y, 0, sourceImage.height - 1);

        if (red(edgeMap.get(x, y)) > 200) {
            edgeScore += 1;
        }
    }

    let importance = (length / config.maxCableLength) * 5 + (edgeScore / samples) * 10;

    // Create cable with the chosen cluster color
    return {
        start: startJack.id,
        end: endJack.id,
        color: colorClusters[closestClusterIndex],
        startPoint: { x: startJack.x, y: startJack.y },
        endPoint: { x: endJack.x, y: endJack.y },
        importance: importance
    };
}

function draw() {
    background(config.backgroundColor);

    if (!imageLoaded) {
        // Show loading message
        fill(255);
        textSize(20);
        textAlign(CENTER, CENTER);
        text("Loading image...", width / 2, height / 2);
        return;
    }

    // Optionally show the original image in the background
    if (config.showOriginalImage) {
        push();
        tint(255, 40); // Show with low opacity
        image(sourceImage, 0, 0);
        noTint();
        pop();
    }

    // Draw existing cables
    drawCables();

    // Progressive rendering - add cables gradually
    if (config.progressiveRendering && pendingCables.length > 0) {
        // Add a few cables each frame
        for (let i = 0; i < config.cablesPerFrame && pendingCables.length > 0; i++) {
            cables.push(pendingCables.shift());
            buildProgress++;
        }
    }

    // Optionally draw jacks (connection points)
    if (config.showJacks) {
        drawJacks();
    }

    // Display progress
    if (pendingCables.length > 0) {
        let progress = (buildProgress / (buildProgress + pendingCables.length)) * 100;
        fill(255);
        noStroke();
        textSize(14);
        textAlign(LEFT, TOP);
        text(`Progress: ${floor(progress)}%`, 10, 10);
    }
}

function drawCables() {
    // Draw each cable as a simple line with its color
    cables.forEach(cable => {
        stroke(cable.color);
        strokeWeight(config.cableThickness);
        line(cable.startPoint.x, cable.startPoint.y,
            cable.endPoint.x, cable.endPoint.y);
    });
}

function drawJacks() {
    // Draw jack points
    noStroke();
    fill(255, 30);
    points.forEach(p => {
        if (p.isJack) {
            circle(p.x, p.y, config.jackRadius * 2);
        }
    });
}

// Utility function to shuffle an array
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

function windowResized() {
    // Always resize to fill the window
    canvasWidth = windowWidth;
    canvasHeight = windowHeight;
    resizeCanvas(canvasWidth, canvasHeight);

    if (sourceImage) {
        // Resize image to fill the canvas completely
        sourceImage.resize(canvasWidth, canvasHeight);

        // Re-analyze image and reset simulation
        analyzeImage();
        generateColorClusters();
        resetSimulation();
    }
}

// Key controls
function keyPressed() {
    if (key === 'r' || key === 'R') {
        resetSimulation();
    }

    // Toggle jack visibility
    if (key === 'j' || key === 'J') {
        config.showJacks = !config.showJacks;
    }

    // Toggle original image in background
    if (key === 'i' || key === 'I') {
        config.showOriginalImage = !config.showOriginalImage;
    }

    // Toggle progressive rendering
    if (key === 'p' || key === 'P') {
        config.progressiveRendering = !config.progressiveRendering;
        if (!config.progressiveRendering) {
            // Add all pending cables immediately
            cables = cables.concat(pendingCables);
            pendingCables = [];
        }
    }

    // Increase/decrease line count
    if (key === '+' || key === '=') {
        config.cableCount += 100;
        resetSimulation();
    }

    if (key === '-' || key === '_') {
        config.cableCount = max(50, config.cableCount - 100);
        resetSimulation();
    }
}