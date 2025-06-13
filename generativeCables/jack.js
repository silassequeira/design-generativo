class Jack {
    constructor(x, y, id, config) {
        this.x = x;
        this.y = y;
        this.fixed = true;
        this.isJack = true;
        this.id = id;
        this.connected = false;
        this.config = config;
    }

    draw() {
        // Draw jack background
        fill(40);
        noStroke();
        circle(this.x, this.y, this.config.jackRadius * 1.5);

        // Draw jack
        fill(this.connected ? color(150, 210, 150) : this.config.jackColor);
        stroke(30);
        strokeWeight(1);
        circle(this.x, this.y, this.config.jackRadius);
    }

    connect() {
        this.connected = true;
    }

    disconnect() {
        this.connected = false;
    }

    // Static method to create all jacks in the grid layout
    static createJacks(canvasWidth, canvasHeight, config) {
        let jacks = [];
        let jackId = 0;

        // Top row of jacks
        const topJackCount = 8;
        for (let i = 0; i < topJackCount; i++) {
            jacks.push(new Jack(
                (canvasWidth / (topJackCount + 1)) * (i + 1),
                80,
                jackId++,
                config
            ));
        }

        // Bottom row of jacks
        const bottomJackCount = 8;
        for (let i = 0; i < bottomJackCount; i++) {
            jacks.push(new Jack(
                (canvasWidth / (bottomJackCount + 1)) * (i + 1),
                canvasHeight - 80,
                jackId++,
                config
            ));
        }

        // Middle row of jacks
        const middleJackCount = 8;
        for (let i = 0; i < middleJackCount; i++) {
            jacks.push(new Jack(
                (canvasWidth / (middleJackCount + 1)) * (i + 1),
                canvasHeight / 2,
                jackId++,
                config
            ));
        }

        // Left column of jacks
        const leftJackCount = 3;
        for (let i = 0; i < leftJackCount; i++) {
            jacks.push(new Jack(
                80,
                (canvasHeight / (leftJackCount + 1)) * (i + 1),
                jackId++,
                config
            ));
        }

        // Right column of jacks
        const rightJackCount = 3;
        for (let i = 0; i < rightJackCount; i++) {
            jacks.push(new Jack(
                canvasWidth - 80,
                (canvasHeight / (rightJackCount + 1)) * (i + 1),
                jackId++,
                config
            ));
        }

        return jacks;
    }
}