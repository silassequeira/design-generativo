let visualizer;

function setup() {
    visualizer = new SynthVisualizer();
    visualizer.setup();
}

function draw() {
    visualizer.draw();
}

function windowResized() {
    visualizer.windowResized();
}