class Cable {
    constructor(startJack, endJack, config) {
        this.start = startJack.id;
        this.end = endJack.id;
        this.startJack = startJack;
        this.endJack = endJack;
        this.config = config;
        this.color = this.generateColor();
        this.points = this.createCablePoints(startJack, endJack);
        this.age = 0;
        this.connectionProgress = 0;
        this.disconnectionProgress = 0;

        // Mark jacks as connected
        startJack.connect();
        endJack.connect();
    }

    generateColor() {
        const colorType = floor(random(4));
        switch (colorType) {
            case 0: return color(35, 139, 47, 220); // Green
            case 1: return color(255, 102, 0, 220); // Orange
            case 2: return color(226, 190, 82, 220); // Yellow
            case 3: return color(79, 121, 120, 220); // Blue
        }
    }

    createCablePoints(start, end) {
        let cablePoints = [];

        // Start point (fixed at jack)
        cablePoints.push({
            x: start.x,
            y: start.y,
            prevX: start.x,
            prevY: start.y,
            fixed: true,
            isConnector: true
        });

        // Calculate direct distance for reference
        const directDistance = dist(start.x, start.y, end.x, end.y);

        // Create more segments for longer cables
        const segmentCount = this.config.cableSegments + floor(directDistance / 200);

        // Generate cable segments with significant initial droop
        for (let i = 1; i < segmentCount; i++) {
            const t = i / segmentCount;

            // Create a drooping curve effect
            let x = lerp(start.x, end.x, t);
            let y = lerp(start.y, end.y, t);

            // Add substantial droop to the cable - increase droopFactor
            const droopFactor = directDistance / 2.5; // More aggressive drooping
            const droop = sin(t * PI) * droopFactor;

            // Apply droop - pull down more in the middle
            y += droop;

            // Add significant randomness for a more natural look
            if (i > 1 && i < segmentCount - 1) {
                x += random(-20, 20);
                y += random(-10, 30); // Bias downward
            }

            cablePoints.push({
                x: x,
                y: y,
                prevX: x,
                prevY: y,
                fixed: false
            });
        }

        // End point (fixed at jack)
        cablePoints.push({
            x: end.x,
            y: end.y,
            prevX: end.x,
            prevY: end.y,
            fixed: true,
            isConnector: true
        });

        return cablePoints;
    }

    updatePhysics() {
        const cablePoints = this.points;

        // Update positions using Verlet integration
        for (let i = 0; i < cablePoints.length; i++) {
            const p = cablePoints[i];
            if (!p.fixed) {
                // Calculate velocity from previous position
                const vx = (p.x - p.prevX) * this.config.dampening;
                const vy = (p.y - p.prevY) * this.config.dampening;

                // Save current position as previous
                p.prevX = p.x;
                p.prevY = p.y;

                // Apply velocity and gravity
                p.x += vx;
                p.y += vy + this.config.gravity;
            }
        }

        // Enforce cable segment length constraints
        const constraintIterations = this.config.tension;
        for (let iteration = 0; iteration < constraintIterations; iteration++) {
            for (let i = 0; i < cablePoints.length - 1; i++) {
                const p1 = cablePoints[i];
                const p2 = cablePoints[i + 1];

                // Calculate distance between points
                const dx = p2.x - p1.x;
                const dy = p2.y - p1.y;
                const currentDistance = sqrt(dx * dx + dy * dy);

                // Make rest distance 25-40% longer than needed
                const excessFactor = 1.3 + sin(i * 0.5) * 0.1;  // Varies between 1.2-1.4
                const restDistance = 25 * excessFactor;

                // Calculate the difference from rest length
                const difference = (restDistance - currentDistance) / currentDistance;

                // Apply a more relaxed correction
                const relaxFactor = 0.25;
                const offsetX = dx * relaxFactor * difference;
                const offsetY = dy * relaxFactor * difference;

                // Move points to maintain cable segment length
                if (!p1.fixed) {
                    p1.x -= offsetX;
                    p1.y -= offsetY;
                }
                if (!p2.fixed) {
                    p2.x += offsetX;
                    p2.y += offsetY;
                }
            }
        }
    }

    draw() {
        // Draw the cable
        stroke(this.color);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();
        for (let p of this.points) {
            vertex(p.x, p.y);
        }
        endShape();
    }

    drawConnection() {
        const progress = this.connectionProgress;
        const cablePoints = this.points;
        const lastIndex = floor(lerp(0, cablePoints.length - 1, progress));

        if (lastIndex <= 0) return;

        // Draw the cable up to the current progress
        stroke(this.color);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();
        for (let i = 0; i <= lastIndex; i++) {
            vertex(cablePoints[i].x, cablePoints[i].y);
        }

        // If we're between points, draw to the interpolated position
        if (lastIndex < cablePoints.length - 1) {
            const partialProgress = (progress * (cablePoints.length - 1)) % 1;
            const nextPoint = cablePoints[lastIndex + 1];
            const currentPoint = cablePoints[lastIndex];
            const x = lerp(currentPoint.x, nextPoint.x, partialProgress);
            const y = lerp(currentPoint.y, nextPoint.y, partialProgress);
            vertex(x, y);
        }

        endShape();
    }

    drawDisconnection() {
        const progress = this.disconnectionProgress;
        const cablePoints = this.points;
        const firstIndex = floor(lerp(0, cablePoints.length - 1, progress));

        if (firstIndex >= cablePoints.length - 1) return;

        // Draw the cable from current progress to end
        stroke(this.color);
        strokeWeight(this.config.cableThickness);
        noFill();

        beginShape();

        // If we're between points, start from the interpolated position
        if (firstIndex > 0) {
            const partialProgress = (progress * (cablePoints.length - 1)) % 1;
            const prevPoint = cablePoints[firstIndex - 1];
            const currentPoint = cablePoints[firstIndex];
            const x = lerp(prevPoint.x, currentPoint.x, partialProgress);
            const y = lerp(prevPoint.y, currentPoint.y, partialProgress);
            vertex(x, y);
        }

        for (let i = firstIndex; i < cablePoints.length; i++) {
            vertex(cablePoints[i].x, cablePoints[i].y);
        }

        endShape();
    }

    drawConnectors() {
        // Get first and last points of the cable
        const startPoint = this.points[0];
        const endPoint = this.points[this.points.length - 1];

        // Draw connectors
        this.drawConnector(startPoint);
        this.drawConnector(endPoint);
    }

    drawConnector(point) {
        // Extract base color from the cable color
        const r = red(this.color);
        const g = green(this.color);
        const b = blue(this.color);

        // Draw connector
        fill(215, 206, 197);
        stroke(30);
        strokeWeight(1);
        circle(point.x, point.y, this.config.connectorRadius);

        // Draw connector details
        fill(20);
        noStroke();
        circle(point.x, point.y, this.config.connectorRadius * 0.5);

        // Draw subtle colored highlight
        fill(r, g, b, 100);
        noStroke();
        circle(point.x, point.y, this.config.connectorRadius * 0.3);
    }

    updateConnectionProgress(deltaTime) {
        this.connectionProgress += deltaTime / this.config.connectionDuration;
        return this.connectionProgress >= 1;
    }

    updateDisconnectionProgress(deltaTime) {
        this.disconnectionProgress += deltaTime / this.config.connectionDuration;
        return this.disconnectionProgress >= 1;
    }
}