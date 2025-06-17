class Jack {
    float x;
    float y;
    boolean fixed;
    boolean isJack;
    int id;
    boolean connected;
    Config config;

    Jack(float x, float y, int id, Config config) {
        this.x = x;
        this.y = y;
        this.fixed = true;
        this.isJack = true;
        this.id = id;
        this.connected = false;
        this.config = config;
    }

    void draw() {
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

    void connect() {
        this.connected = true;
    }

    void disconnect() {
        this.connected = false;
    }
}

// Move the static method to a separate utility class
class JackFactory {
    // Create all jacks in the grid layout
    ArrayList<Jack> createJacks(float canvasWidth, float canvasHeight, Config config) {
        ArrayList<Jack> jacks = new ArrayList<Jack>();
        int jackId = 0;

        // Top row of jacks
        int topJackCount = 8;
        for (int i = 0; i < topJackCount; i++) {
            jacks.add(new Jack(
                (canvasWidth / (topJackCount + 1)) * (i + 1),
                80,
                jackId++,
                config
            ));
        }

        // Bottom row of jacks
        int bottomJackCount = 8;
        for (int i = 0; i < bottomJackCount; i++) {
            jacks.add(new Jack(
                (canvasWidth / (bottomJackCount + 1)) * (i + 1),
                canvasHeight - 80,
                jackId++,
                config
            ));
        }

        // Middle row of jacks
        int middleJackCount = 8;
        for (int i = 0; i < middleJackCount; i++) {
            jacks.add(new Jack(
                (canvasWidth / (middleJackCount + 1)) * (i + 1),
                canvasHeight / 2,
                jackId++,
                config
            ));
        }

        // Left column of jacks
        int leftJackCount = 3;
        for (int i = 0; i < leftJackCount; i++) {
            jacks.add(new Jack(
                80,
                (canvasHeight / (leftJackCount + 1)) * (i + 1),
                jackId++,
                config
            ));
        }

        // Right column of jacks
        int rightJackCount = 3;
        for (int i = 0; i < rightJackCount; i++) {
            jacks.add(new Jack(
                canvasWidth - 80,
                (canvasHeight / (rightJackCount + 1)) * (i + 1),
                jackId++,
                config
            ));
        }

        return jacks;
    }
}
