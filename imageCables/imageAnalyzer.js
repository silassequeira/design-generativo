class ImageAnalyzer {
    constructor(config) {
        this.config = config;
        this.sourceImage = null;
        this.edgeMap = null;
        this.brightnessMap = null;
        this.colorClusters = [];
        this.imageLoaded = false;
    }

    preloadImage(path, successCallback, errorCallback) {
        loadImage(
            path,
            (img) => {
                this.sourceImage = img;
                this.imageLoaded = true;
                if (successCallback) successCallback();
            },
            () => {
                console.error("Failed to load image");
                if (errorCallback) errorCallback();
            }
        );
    }

    resizeImage(width, height) {
        if (this.sourceImage) {
            this.sourceImage.resize(width, height);
        }
    }

    analyzeImage() {
        if (!this.imageLoaded) return;

        console.log("Analyzing image...");

        // Create the edge and brightness maps
        this.edgeMap = createGraphics(this.sourceImage.width, this.sourceImage.height);
        this.brightnessMap = createGraphics(this.sourceImage.width, this.sourceImage.height);

        // Set willReadFrequently attribute for better performance
        this.edgeMap.drawingContext.canvas.willReadFrequently = true;
        this.brightnessMap.drawingContext.canvas.willReadFrequently = true;

        // Draw the source image to both graphics buffers
        this.edgeMap.image(this.sourceImage, 0, 0);
        this.brightnessMap.image(this.sourceImage, 0, 0);

        // Process the brightness map
        this.brightnessMap.loadPixels();
        for (let i = 0; i < this.brightnessMap.pixels.length; i += 4) {
            // Calculate brightness
            let r = this.brightnessMap.pixels[i];
            let g = this.brightnessMap.pixels[i + 1];
            let b = this.brightnessMap.pixels[i + 2];
            let brightness = (r + g + b) / 3;

            // Set all channels to brightness value for easier reading later
            this.brightnessMap.pixels[i] = brightness;
            this.brightnessMap.pixels[i + 1] = brightness;
            this.brightnessMap.pixels[i + 2] = brightness;
        }
        this.brightnessMap.updatePixels();

        // Process the edge map - use a more sophisticated edge detection
        this.edgeMap.filter(GRAY);

        // Create a temporary graphics buffer for edge detection
        let edgeTemp = createGraphics(this.edgeMap.width, this.edgeMap.height);
        edgeTemp.image(this.edgeMap, 0, 0);

        // Apply more sophisticated edge detection
        this.edgeMap.loadPixels();
        edgeTemp.loadPixels();

        // Simple Sobel-like edge detection
        for (let x = 1; x < this.edgeMap.width - 1; x++) {
            for (let y = 1; y < this.edgeMap.height - 1; y++) {
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
                let edgePixel = edgeStrength > this.config.edgeThreshold ? 255 : 0;

                // Set pixel in edge map
                let idx = 4 * (y * this.edgeMap.width + x);
                this.edgeMap.pixels[idx] = edgePixel;
                this.edgeMap.pixels[idx + 1] = edgePixel;
                this.edgeMap.pixels[idx + 2] = edgePixel;
            }
        }

        this.edgeMap.updatePixels();
        edgeTemp.remove(); // Clean up temporary buffer

        console.log("Image analysis complete.");
    }

    generateColorClusters() {
        if (!this.imageLoaded) return;

        console.log("Generating color clusters...");

        // Sample colors from the image
        let sampleCount = 2000; // Number of random sample points
        let colorSamples = [];

        // Take random samples from the image
        for (let i = 0; i < sampleCount; i++) {
            let x = floor(random(this.sourceImage.width));
            let y = floor(random(this.sourceImage.height));
            let c = this.sourceImage.get(x, y);
            colorSamples.push({
                r: red(c),
                g: green(c),
                b: blue(c)
            });
        }

        // Simple k-means clustering
        let k = this.config.colorPalette; // Number of clusters
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
                    let dist = this.colorDistance(sample, centroid);
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
        this.colorClusters = centroids.map(c => color(c.r, c.g, c.b, this.config.alpha));

        console.log("Generated", this.colorClusters.length, "color clusters");
    }

    colorDistance(color1, color2) {
        // Simple Euclidean distance in RGB space
        return sqrt(
            sq(color1.r - color2.r) +
            sq(color1.g - color2.g) +
            sq(color1.b - color2.b)
        );
    }

    getLocalContrast(x, y) {
        if (!this.brightnessMap) return 0;

        // Sample a small region around the point to determine local contrast
        const radius = 5;
        let samples = [];

        for (let dx = -radius; dx <= radius; dx += 2) {
            for (let dy = -radius; dy <= radius; dy += 2) {
                let sx = constrain(x + dx, 0, this.sourceImage.width - 1);
                let sy = constrain(y + dy, 0, this.sourceImage.height - 1);
                samples.push(red(this.brightnessMap.get(sx, sy)));
            }
        }

        // Calculate standard deviation as a measure of contrast
        const mean = samples.reduce((sum, val) => sum + val, 0) / samples.length;
        const variance = samples.reduce((sum, val) => sum + sq(val - mean), 0) / samples.length;
        return sqrt(variance) / 255; // Normalized contrast value (0-1)
    }

    getEdgeAngle(x, y) {
        if (!this.edgeMap) return 0;

        // Simple estimate of edge direction by sampling neighboring pixels
        const radius = 2;
        let edgeX = 0;
        let edgeY = 0;

        for (let dx = -radius; dx <= radius; dx++) {
            for (let dy = -radius; dy <= radius; dy++) {
                if (dx === 0 && dy === 0) continue;

                let sx = constrain(x + dx, 0, this.edgeMap.width - 1);
                let sy = constrain(y + dy, 0, this.edgeMap.height - 1);

                let edgeValue = red(this.edgeMap.get(sx, sy));
                if (edgeValue > 200) {
                    edgeX += dx;
                    edgeY += dy;
                }
            }
        }

        if (edgeX === 0 && edgeY === 0) return 0;
        return atan2(edgeY, edgeX) + PI / 2; // Rotate 90 degrees to get edge direction
    }

    angleDistance(angle1, angle2) {
        // Calculate the smallest angular distance between two angles
        let diff = (angle2 - angle1) % TWO_PI;
        if (diff > PI) diff -= TWO_PI;
        if (diff < -PI) diff += TWO_PI;
        return diff;
    }
}