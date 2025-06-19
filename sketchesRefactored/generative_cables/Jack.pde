class Jack {
    float x;
    float y;
    int id;
    boolean connected;
    Config config;

    Jack(float x, float y, int id, Config config) {
        this.x = x;
        this.y = y;
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
        fill(this.connected ? color(215, 206, 197) : this.config.jackColor);
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

class CablePoint {
    float x, y;           // Current position
    float prevX, prevY;   // Previous position
    boolean fixed;        // Whether this point can move
    boolean isConnector;  // Whether this is an end connector

    CablePoint() {
        isConnector = false;
    }
    
    CablePoint(float x, float y, boolean fixed, boolean isConnector) {
        this.x = x;
        this.y = y;
        this.prevX = x;
        this.prevY = y;
        this.fixed = fixed;
        this.isConnector = isConnector;
    }
}
