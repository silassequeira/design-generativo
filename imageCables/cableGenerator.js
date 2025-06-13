class CableGenerator {
    constructor(config, imageAnalyzer, jackManager) {
        this.config = config;
        this.imageAnalyzer = imageAnalyzer;
        this.jackManager = jackManager;
        this.cables = [];
        this.pendingCables = [];
        this.buildProgress = 0;
    }

    planCablesFromImage() {
        this.cables = [];
        this.pendingCables = [];
        this.buildProgress = 0;

        if (!this.imageAnalyzer.imageLoaded) return;

        const jackPoints = this.jackManager.jacks;
        let attemptedConnections = new Set(); // Track attempted connections

        console.log("Planning cables...");

        // Create cables that represent the image
        let cablesPlanned = 0;
        let attempts = 0;
        const maxAttempts = 7000; // More attempts for better quality

        // Keep trying until we have enough planned cables or run out of attempts
        while (cablesPlanned < this.config.cableCount && attempts < maxAttempts) {
            attempts++;

            // Find jacks that aren't already connected too many times
            let availableJacks = jackPoints.filter(p =>
                p.connections < this.config.maxConnectionsPerJack
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
                return distance >= this.config.minCableLength &&
                    distance <= this.config.maxCableLength;
            });

            if (potentialTargets.length === 0) continue;

            // Find a target that best represents the image
            let bestTargetIndex = 0;
            let bestTargetScore = -1;

            for (let i = 0; i < min(potentialTargets.length, 10); i++) {
                let targetJack = potentialTargets[i];
                let score = this.evaluateConnectionQuality(startJack, targetJack);

                if (score > bestTargetScore) {
                    bestTargetScore = score;
                    bestTargetIndex = i;
                }
            }

            if (bestTargetScore > 0) {
                let bestTarget = potentialTargets[bestTargetIndex];

                // Create the cable and add to pending list
                let newCable = this.createCable(startJack, bestTarget);
                this.pendingCables.push(newCable);

                // Update connection count for both jacks
                startJack.connections++;
                bestTarget.connections++;

                cablesPlanned++;
            }
        }

        // Sort cables by their visual importance
        this.pendingCables.sort((a, b) => b.importance - a.importance);

        console.log(`Planned ${cablesPlanned} cables after ${attempts} attempts`);
    }

    evaluateConnectionQuality(jack1, jack2) {
        if (!this.imageAnalyzer.sourceImage) return 0;

        // Sample colors and edges along the potential cable path
        const samples = this.config.colorSamples;
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
            x = constrain(x, 0, this.imageAnalyzer.sourceImage.width - 1);
            y = constrain(y, 0, this.imageAnalyzer.sourceImage.height - 1);

            // Sample colors
            let imgColor = this.imageAnalyzer.sourceImage.get(x, y);
            sampleColors.push(imgColor);

            // Check if on edge
            let edgeValue = red(this.imageAnalyzer.edgeMap.get(x, y));
            if (edgeValue > 200) {
                edgeFollowing++;

                // Extra bonus if the line follows an edge
                if (i > 0 && i < samples) {
                    // Check if the edge direction matches the line
                    let edgeAngle = this.imageAnalyzer.getEdgeAngle(x, y);
                    let angleDiff = abs(this.imageAnalyzer.angleDistance(angle, edgeAngle));

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
        let edgeScore = (edgeFollowing / samples) * this.config.edgePreference * 15;

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

    createCable(startJack, endJack) {
        if (!this.imageAnalyzer.sourceImage) {
            return null;
        }

        // Sample colors along the path to determine best color
        const samples = 8;
        let sampleColors = [];

        // Sample multiple points to get colors
        for (let i = 0; i <= samples; i++) {
            let t = i / samples;
            let x = floor(lerp(startJack.x, endJack.x, t));
            let y = floor(lerp(startJack.y, endJack.y, t));

            // Constrain to image bounds
            x = constrain(x, 0, this.imageAnalyzer.sourceImage.width - 1);
            y = constrain(y, 0, this.imageAnalyzer.sourceImage.height - 1);

            // Get image color at this point
            let imgColor = this.imageAnalyzer.sourceImage.get(x, y);
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

        for (let i = 0; i < this.imageAnalyzer.colorClusters.length; i++) {
            let cluster = this.imageAnalyzer.colorClusters[i];
            let dist = this.imageAnalyzer.colorDistance(avgColor, {
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
            x = constrain(x, 0, this.imageAnalyzer.sourceImage.width - 1);
            y = constrain(y, 0, this.imageAnalyzer.sourceImage.height - 1);

            if (red(this.imageAnalyzer.edgeMap.get(x, y)) > 200) {
                edgeScore += 1;
            }
        }

        let importance = (length / this.config.maxCableLength) * 5 + (edgeScore / samples) * 10;

        // Create cable with the chosen cluster color
        return {
            start: startJack.id,
            end: endJack.id,
            color: this.imageAnalyzer.colorClusters[closestClusterIndex],
            startPoint: { x: startJack.x, y: startJack.y },
            endPoint: { x: endJack.x, y: endJack.y },
            importance: importance
        };
    }

    addCablesProgressively() {
        if (this.config.progressiveRendering && this.pendingCables.length > 0) {
            // Add a few cables each frame
            for (let i = 0; i < this.config.cablesPerFrame && this.pendingCables.length > 0; i++) {
                this.cables.push(this.pendingCables.shift());
                this.buildProgress++;
            }
            return true;
        }
        return false;
    }

    addAllCablesImmediately() {
        this.cables = this.cables.concat(this.pendingCables);
        this.buildProgress += this.pendingCables.length;
        this.pendingCables = [];
    }

    drawCables() {
        // Draw each cable as a simple line with its color
        this.cables.forEach(cable => {
            stroke(cable.color);
            strokeWeight(this.config.cableThickness);
            line(
                cable.startPoint.x, cable.startPoint.y,
                cable.endPoint.x, cable.endPoint.y
            );
        });
    }

    getProgress() {
        const total = this.buildProgress + this.pendingCables.length;
        if (total === 0) return 100;
        return (this.buildProgress / total) * 100;
    }

    reset() {
        this.cables = [];
        this.pendingCables = [];
        this.buildProgress = 0;
    }
}