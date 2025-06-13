class JackManager {
    constructor(config, imageAnalyzer) {
        this.config = config;
        this.imageAnalyzer = imageAnalyzer;
        this.jacks = [];
    }

    createJacksFromImage() {
        this.jacks = [];

        if (!this.imageAnalyzer.imageLoaded) return;

        const sourceImage = this.imageAnalyzer.sourceImage;

        // Get image dimensions
        const imgWidth = sourceImage.width;
        const imgHeight = sourceImage.height;

        // Calculate grid spacing based on image size
        const gridSpacing = floor(max(10, min(imgWidth, imgHeight) / 40));
        let jackPositions = [];

        // Create a grid of potential positions
        for (let x = gridSpacing; x < imgWidth; x += gridSpacing) {
            for (let y = gridSpacing; y < imgHeight; y += gridSpacing) {
                jackPositions.push({ x, y });
            }
        }

        // Shuffle the positions
        jackPositions = this.shuffleArray(jackPositions);

        // Create jacks with strategic placement
        let jacksPlaced = 0;
        let i = 0;

        while (jacksPlaced < this.config.maxJacks && i < jackPositions.length) {
            let pos = jackPositions[i];
            i++;

            // Sample edge value and brightness
            let edgeValue = red(this.imageAnalyzer.edgeMap.get(pos.x, pos.y));
            let brightness = red(this.imageAnalyzer.brightnessMap.get(pos.x, pos.y));

            // Higher probability near edges and in areas with more contrast
            let placementProbability = 0.1; // Base probability

            if (edgeValue > 200) {
                placementProbability += 0.6; // Much higher on edges
            }

            // Prefer areas with high contrast
            const contrast = this.imageAnalyzer.getLocalContrast(pos.x, pos.y);
            placementProbability += contrast * 0.3;

            // Add probability based on brightness - favor areas with more detail
            if (brightness < 50 || brightness > 200) {
                placementProbability += 0.2; // Higher in very dark or bright areas
            }

            if (random() < placementProbability) {
                // Create the jack with a small random offset for more natural appearance
                this.jacks.push({
                    x: pos.x + random(-2, 2),
                    y: pos.y + random(-2, 2),
                    fixed: true,
                    isJack: true,
                    id: this.jacks.length,
                    connections: 0
                });

                jacksPlaced++;
            }
        }

        // Add some additional jacks in areas with few jacks
        this.addSupplementalJacks();

        return this.jacks;
    }

    addSupplementalJacks() {
        if (!this.imageAnalyzer.sourceImage) return;

        const sourceImage = this.imageAnalyzer.sourceImage;

        // First identify areas with low jack density
        const cellSize = 40;
        const rows = ceil(sourceImage.height / cellSize);
        const cols = ceil(sourceImage.width / cellSize);
        let grid = new Array(rows * cols).fill(0);

        // Count jacks in each cell
        for (let p of this.jacks) {
            let col = floor(p.x / cellSize);
            let row = floor(p.y / cellSize);
            let index = row * cols + col;
            if (index >= 0 && index < grid.length) {
                grid[index]++;
            }
        }

        // Add jacks in cells with few or no jacks
        const additionalJacks = min(100, this.config.maxJacks * 0.2);
        let added = 0;

        for (let i = 0; i < grid.length && added < additionalJacks; i++) {
            if (grid[i] < 1) {
                let row = floor(i / cols);
                let col = i % cols;
                let x = col * cellSize + random(5, cellSize - 5);
                let y = row * cellSize + random(5, cellSize - 5);

                // Make sure it's within image bounds
                if (x >= 0 && x < sourceImage.width && y >= 0 && y < sourceImage.height) {
                    this.jacks.push({
                        x: x,
                        y: y,
                        fixed: true,
                        isJack: true,
                        id: this.jacks.length,
                        connections: 0
                    });
                    added++;
                }
            }
        }
    }

    drawJacks() {
        if (!this.config.showJacks) return;

        // Draw jack points
        noStroke();
        fill(255, 30);
        this.jacks.forEach(jack => {
            circle(jack.x, jack.y, this.config.jackRadius * 2);
        });
    }

    getJack(id) {
        return this.jacks.find(jack => jack.id === id);
    }

    resetJackConnections() {
        for (let jack of this.jacks) {
            jack.connections = 0;
        }
    }

    // Utility function to shuffle an array
    shuffleArray(array) {
        const newArray = [...array];
        for (let i = newArray.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
        }
        return newArray;
    }
}