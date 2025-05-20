// Wendy Carlos Synthesizer Cable Visualization - Autonomous Animation
// Generative patching cable animation

// Configuration
let config = {
    cableCount: 8,
    gravity: 0.2,
    tension: 5,
    cableSegments: 12,
    cableThickness: 4,
    jackRadius: 15,
    connectorRadius: 12,
    dampening: 0.98,
    backgroundColor: [20, 20, 30],
    jackColor: [200, 100, 50],

    // Animation settings
    connectionInterval: 3000,   // Time in ms between connection changes
    connectionDuration: 1000,   // Time in ms for connection animation
    autoGravityRange: [0.05, 0.25], // Min and max for gravity oscillation
    autoTensionRange: [3, 8]    // Min and max for tension oscillation
};

// Main variables
let points = [];
let cables = [];
let canvasWidth, canvasHeight;

// Animation state
let lastConnectionTime = 0;
let connectionsInProgress = [];
let disconnectionsInProgress = [];
let globalAnimationTime = 0;

function setup() {
    // Create canvas that fills the window
    canvasWidth = windowWidth;
    canvasHeight = windowHeight;
    let canvas = createCanvas(canvasWidth, canvasHeight);
    canvas.parent('canvas-container');

    // Initialize the visualization
    resetSimulation();

    // Start with fewer cables so we can see them being created
    cables = cables.slice(0, 3);
}

function resetSimulation() {
    points = [];
    cables = [];
    connectionsInProgress = [];
    disconnectionsInProgress = [];

    // Create fixed connection points (like synthesizer jacks)
    createJacks();

    // Create initial cables between random points
    createCables();
}

function createJacks() {
    // Top row of jacks
    const topJackCount = 8;
    for (let i = 0; i < topJackCount; i++) {
        points.push({
            x: (canvasWidth / (topJackCount + 1)) * (i + 1),
            y: 80,
            fixed: true,
            isJack: true,
            id: points.length,
            connected: false
        });
    }

    // Bottom row of jacks
    const bottomJackCount = 8;
    for (let i = 0; i < bottomJackCount; i++) {
        points.push({
            x: (canvasWidth / (bottomJackCount + 1)) * (i + 1),
            y: canvasHeight - 80,
            fixed: true,
            isJack: true,
            id: points.length,
            connected: false
        });
    }

    // Middle row of jacks
    const middleJackCount = 8;
    for (let i = 0; i < middleJackCount; i++) {
        points.push({
            x: (canvasWidth / (middleJackCount + 1)) * (i + 1),
            y: canvasHeight / 2,
            fixed: true,
            isJack: true,
            id: points.length,
            connected: false
        });
    }

    // Left column of jacks
    const leftJackCount = 3;
    for (let i = 0; i < leftJackCount; i++) {
        points.push({
            x: 80,
            y: (canvasHeight / (leftJackCount + 1)) * (i + 1),
            fixed: true,
            isJack: true,
            id: points.length,
            connected: false
        });
    }

    // Right column of jacks
    const rightJackCount = 3;
    for (let i = 0; i < rightJackCount; i++) {
        points.push({
            x: canvasWidth - 80,
            y: (canvasHeight / (rightJackCount + 1)) * (i + 1),
            fixed: true,
            isJack: true,
            id: points.length,
            connected: false
        });
    }
}

function createCable(startJack, endJack) {
    // Using color palette from Colors.txt
    let cableColor;
    const colorType = floor(random(4));
    switch (colorType) {
        case 0: cableColor = color(35, 139, 47, 220); break;   // Green
        case 1: cableColor = color(255, 102, 0, 220); break;   // Orange
        case 2: cableColor = color(226, 190, 82, 220); break;  // Yellow
        case 3: cableColor = color(79, 121, 120, 220); break;  // Blue
    }

    // Mark jacks as connected
    startJack.connected = true;
    endJack.connected = true;

    return {
        start: startJack.id,
        end: endJack.id,
        color: cableColor,
        points: createCablePoints(startJack, endJack),
        age: 0,
        connectionProgress: 0
    };
}

function createCables() {
    const jackPoints = points.filter(p => p.isJack);

    // Create cables between random jacks
    for (let i = 0; i < config.cableCount; i++) {
        let startIndex = floor(random(jackPoints.length));
        let endIndex;
        do {
            endIndex = floor(random(jackPoints.length));
        } while (startIndex === endIndex);

        const startJack = jackPoints[startIndex];
        const endJack = jackPoints[endIndex];

        cables.push(createCable(startJack, endJack));
    }
}

function createCablePoints(start, end) {
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

    // Generate cable segments with a gentle initial curve
    for (let i = 1; i < config.cableSegments; i++) {
        const t = i / config.cableSegments;

        // Create a drooping curve effect
        let x = lerp(start.x, end.x, t);
        let y = lerp(start.y, end.y, t);

        // Add some initial droop to the cable
        const distance = dist(start.x, start.y, end.x, end.y);

        // More droop for longer cables and for middle segments
        const droopFactor = distance / 5;
        const droop = sin(t * PI) * droopFactor;

        y += droop;

        // Add some randomness to create a more natural look
        if (i > 1 && i < config.cableSegments - 1) {
            x += random(-10, 10);
            y += random(-10, 10);
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

function updatePhysics() {
    // Apply physics to each cable
    cables.forEach(cable => {
        const cablePoints = cable.points;

        // Update positions using Verlet integration
        for (let i = 0; i < cablePoints.length; i++) {
            const p = cablePoints[i];
            if (!p.fixed) {
                // Calculate velocity from previous position
                const vx = (p.x - p.prevX) * config.dampening;
                const vy = (p.y - p.prevY) * config.dampening;

                // Save current position as previous
                p.prevX = p.x;
                p.prevY = p.y;

                // Apply velocity and gravity
                p.x += vx;
                p.y += vy + config.gravity;
            }
        }

        // Enforce cable segment length constraints
        const constraintIterations = config.tension;
        for (let iteration = 0; iteration < constraintIterations; iteration++) {
            for (let i = 0; i < cablePoints.length - 1; i++) {
                const p1 = cablePoints[i];
                const p2 = cablePoints[i + 1];

                // Calculate distance between points
                const dx = p2.x - p1.x;
                const dy = p2.y - p1.y;
                const currentDistance = sqrt(dx * dx + dy * dy);

                // Desired distance between cable segments
                const restDistance = 20;

                // Calculate the difference from rest length
                const difference = (restDistance - currentDistance) / currentDistance;

                // Apply correction
                const offsetX = dx * 0.5 * difference;
                const offsetY = dy * 0.5 * difference;

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
    });
}

function manageConnections() {
    globalAnimationTime += deltaTime;

    // Vary gravity and tension over time for more organic movement
    const gravityRange = config.autoGravityRange;
    const tensionRange = config.autoTensionRange;
    config.gravity = map(sin(globalAnimationTime * 0.0005), -1, 1, gravityRange[0], gravityRange[1]);
    config.tension = map(sin(globalAnimationTime * 0.0003 + 1), -1, 1, tensionRange[0], tensionRange[1]);

    // Update connection animations in progress
    updateConnectionAnimations();

    // Check if it's time to make a new connection or disconnection
    if (millis() - lastConnectionTime > config.connectionInterval) {
        lastConnectionTime = millis();

        // Randomly decide to create or remove a connection
        if (random() < 0.6 && cables.length < config.cableCount) {
            // Create a new connection
            createNewConnection();
        } else if (cables.length > 0) {
            // Remove a connection
            removeRandomConnection();
        } else {
            createNewConnection();
        }
    }
}

function createNewConnection() {
    // Find unconnected jacks
    const unconnectedJacks = points.filter(p => p.isJack && !p.connected);

    if (unconnectedJacks.length >= 2) {
        const startIndex = floor(random(unconnectedJacks.length));
        let endIndex;
        do {
            endIndex = floor(random(unconnectedJacks.length));
        } while (startIndex === endIndex);

        const startJack = unconnectedJacks[startIndex];
        const endJack = unconnectedJacks[endIndex];

        // Create new connection and add to in-progress list
        const newCable = createCable(startJack, endJack);
        newCable.connectionProgress = 0;
        connectionsInProgress.push(newCable);
    }
}

function removeRandomConnection() {
    if (cables.length > 0) {
        const cableIndex = floor(random(cables.length));
        const cable = cables[cableIndex];

        // Get the jacks this cable was connected to
        const startJack = points.find(p => p.id === cable.start);
        const endJack = points.find(p => p.id === cable.end);

        // Add to disconnection list
        cable.disconnectionProgress = 0;
        disconnectionsInProgress.push({ cable, index: cableIndex });
    }
}

function updateConnectionAnimations() {
    // Update connecting cables
    for (let i = connectionsInProgress.length - 1; i >= 0; i--) {
        const cable = connectionsInProgress[i];

        // Update animation progress
        cable.connectionProgress += deltaTime / config.connectionDuration;

        if (cable.connectionProgress >= 1) {
            // Animation complete, add to regular cables
            cable.connectionProgress = 1;
            cables.push(cable);
            connectionsInProgress.splice(i, 1);
        }
    }

    // Update disconnecting cables
    for (let i = disconnectionsInProgress.length - 1; i >= 0; i--) {
        const { cable, index } = disconnectionsInProgress[i];

        // Update animation progress
        cable.disconnectionProgress += deltaTime / config.connectionDuration;

        if (cable.disconnectionProgress >= 1) {
            // Animation complete, remove cable
            cables.splice(index, 1);
            disconnectionsInProgress.splice(i, 1);

            // Unlock the jacks for future connections
            const startJack = points.find(p => p.id === cable.start);
            const endJack = points.find(p => p.id === cable.end);
            if (startJack) startJack.connected = false;
            if (endJack) endJack.connected = false;
        }
    }
}

function draw() {
    background(config.backgroundColor);

    // Manage automatic connections/disconnections
    manageConnections();

    // Update physics simulation
    updatePhysics();

    // Draw cables behind jacks and connectors
    drawCables();

    // Draw in-progress connections
    drawConnectionsInProgress();

    // Draw in-progress disconnections
    drawDisconnectionsInProgress();

    // Draw jacks (connection points)
    drawJacks();

    // Draw cable connectors
    drawConnectors();
}

function drawCables() {
    cables.forEach(cable => {
        // Draw the cable
        stroke(cable.color);
        strokeWeight(config.cableThickness);
        noFill();

        beginShape();
        for (let p of cable.points) {
            vertex(p.x, p.y);
        }
        endShape();
    });
}

function drawConnectionsInProgress() {
    connectionsInProgress.forEach(cable => {
        const progress = cable.connectionProgress;
        const cablePoints = cable.points;
        const lastIndex = floor(lerp(0, cablePoints.length - 1, progress));

        if (lastIndex <= 0) return;

        // Draw the cable up to the current progress
        stroke(cable.color);
        strokeWeight(config.cableThickness);
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
    });
}

function drawDisconnectionsInProgress() {
    disconnectionsInProgress.forEach(({ cable }) => {
        const progress = cable.disconnectionProgress;
        const cablePoints = cable.points;
        const firstIndex = floor(lerp(0, cablePoints.length - 1, progress));

        if (firstIndex >= cablePoints.length - 1) return;

        // Draw the cable from current progress to end
        stroke(cable.color);
        strokeWeight(config.cableThickness);
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
    });
}

function drawJacks() {
    points.forEach(p => {
        if (p.isJack) {
            // Draw jack background
            fill(40);
            noStroke();
            circle(p.x, p.y, config.jackRadius * 1.5);

            // Draw jack
            fill(p.connected ? color(150, 210, 150) : config.jackColor);
            stroke(30);
            strokeWeight(1);
            circle(p.x, p.y, config.jackRadius);
        }
    });
}

function drawConnectors() {
    // Draw connectors for regular cables
    cables.forEach(cable => {
        drawCableConnectors(cable);
    });

    // Draw connectors for in-progress connections
    connectionsInProgress.forEach(cable => {
        const progress = cable.connectionProgress;
        if (progress > 0.1) {
            // Only draw the start connector
            const startPoint = cable.points[0];
            drawConnector(startPoint, cable.color);
        }
    });

    // Draw connectors for in-progress disconnections
    disconnectionsInProgress.forEach(({ cable }) => {
        const progress = cable.disconnectionProgress;
        if (progress < 0.9) {
            // Only draw the end connector
            const endPoint = cable.points[cable.points.length - 1];
            drawConnector(endPoint, cable.color);
        }
    });
}

function drawCableConnectors(cable) {
    // Get first and last points of the cable
    const startPoint = cable.points[0];
    const endPoint = cable.points[cable.points.length - 1];

    // Draw connectors
    drawConnector(startPoint, cable.color);
    drawConnector(endPoint, cable.color);
}

function drawConnector(point, cableColor) {
    // Extract base color from the cable color
    const r = red(cableColor);
    const g = green(cableColor);
    const b = blue(cableColor);

    // Draw connector
    fill(60);
    stroke(30);
    strokeWeight(1);
    circle(point.x, point.y, config.connectorRadius);

    // Draw connector details
    fill(20);
    noStroke();
    circle(point.x, point.y, config.connectorRadius * 0.5);

    // Draw subtle colored highlight
    fill(r, g, b, 100);
    noStroke();
    circle(point.x, point.y, config.connectorRadius * 0.3);
}

// Window resize handling
function windowResized() {
    canvasWidth = windowWidth;
    canvasHeight = windowHeight;
    resizeCanvas(canvasWidth, canvasHeight);
    resetSimulation();
}