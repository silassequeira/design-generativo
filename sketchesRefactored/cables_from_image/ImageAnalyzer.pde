class ImageAnalyzer {
  PApplet sketch;
  Config config;
  PImage sourceImage;
  PGraphics edgeMap;
  PGraphics brightnessMap;
  ArrayList<Integer> colorClusters;
  boolean imageLoaded;

  ImageAnalyzer(Config config, PApplet sketch) {
    this.config = config;
    this.sketch = sketch;
    this.colorClusters = new ArrayList<Integer>();
    this.imageLoaded = false;
  }

  void loadImage(String path) {
    try {
      sourceImage = sketch.loadImage(path);

      if (sourceImage != null) {
        imageLoaded = true;
        println("Image loaded successfully");
      } else {
        println("Failed to load image");
      }
    }
    catch (Exception e) {
      println("Error loading image: " + e.getMessage());
      imageLoaded = false;
    }
  }

  void resizeImage(int width, int height) {
    if (sourceImage != null && width > 0 && height > 0) {
      sourceImage.resize(width, height);
    }
  }

  void analyzeImage() {
    if (!imageLoaded || sourceImage == null ||
      sourceImage.width <= 0 || sourceImage.height <= 0) {
      println("Cannot analyze: invalid image");
      return;
    }

    println("Analyzing image...");

    // Create and process maps
    createBrightnessMap();
    createEdgeMap();

    println("Image analysis complete.");
  }

  void createBrightnessMap() {
    brightnessMap = createGraphics(sourceImage.width, sourceImage.height);

    brightnessMap.beginDraw();
    brightnessMap.image(sourceImage, 0, 0);
    brightnessMap.endDraw();

    brightnessMap.loadPixels();
    for (int i = 0; i < brightnessMap.pixels.length; i++) {
      int c = brightnessMap.pixels[i];
      float brightness = (red(c) + green(c) + blue(c)) / 3;
      brightnessMap.pixels[i] = color(brightness, brightness, brightness);
    }
    brightnessMap.updatePixels();
  }

  void createEdgeMap() {
    edgeMap = createGraphics(sourceImage.width, sourceImage.height);

    edgeMap.beginDraw();
    edgeMap.image(sourceImage, 0, 0);
    edgeMap.filter(GRAY);
    edgeMap.endDraw();

    // Create a temporary buffer for edge detection
    PGraphics edgeTemp = createGraphics(edgeMap.width, edgeMap.height);
    edgeTemp.beginDraw();
    edgeTemp.image(edgeMap, 0, 0);
    edgeTemp.endDraw();

    // Apply Sobel-like edge detection
    edgeMap.loadPixels();
    edgeTemp.loadPixels();

    for (int x = 1; x < edgeMap.width - 1; x++) {
      for (int y = 1; y < edgeMap.height - 1; y++) {
        // Apply edge detection algorithm
        float edgeStrength = calculateEdgeStrength(edgeTemp, x, y);

        // Apply threshold
        int edgePixel = edgeStrength > config.edgeThreshold ? 255 : 0;

        // Set pixel in edge map
        int idx = y * edgeMap.width + x;
        edgeMap.pixels[idx] = color(edgePixel, edgePixel, edgePixel);
      }
    }

    edgeMap.updatePixels();
  }

  float calculateEdgeStrength(PGraphics img, int x, int y) {
    // Get surrounding pixels
    float pixNW = brightness(img.get(x - 1, y - 1));
    float pixN = brightness(img.get(x, y - 1));
    float pixNE = brightness(img.get(x + 1, y - 1));
    float pixW = brightness(img.get(x - 1, y));
    float pixE = brightness(img.get(x + 1, y));
    float pixSW = brightness(img.get(x - 1, y + 1));
    float pixS = brightness(img.get(x, y + 1));
    float pixSE = brightness(img.get(x + 1, y + 1));

    // Horizontal and vertical gradient approximations
    float pixH = (pixNW + pixW + pixSW) - (pixNE + pixE + pixSE);
    float pixV = (pixNW + pixN + pixNE) - (pixSW + pixS + pixSE);

    // Gradient magnitude
    return sqrt(pixH * pixH + pixV * pixV);
  }

  void generateColorClusters() {
    if (!imageLoaded || sourceImage == null) return;

    println("Generating color clusters...");

    try {
      // Sample colors from the image
      ArrayList<ColorSample> colorSamples = sampleColorsFromImage(2000);

      // Perform k-means clustering
      ArrayList<ColorSample> centroids = performKMeansClustering(colorSamples);

      // Save the clusters for later use
      colorClusters.clear();
      for (ColorSample c : centroids) {
        colorClusters.add(c.toColor(config.alpha));
      }

      println("Generated " + colorClusters.size() + " color clusters");
    }
    catch (Exception e) {
      println("Error generating color clusters: " + e.getMessage());
    }
  }

  ArrayList<ColorSample> sampleColorsFromImage(int sampleCount) {
    ArrayList<ColorSample> samples = new ArrayList<ColorSample>();

    for (int i = 0; i < sampleCount; i++) {
      int x = floor(random(sourceImage.width));
      int y = floor(random(sourceImage.height));
      int c = sourceImage.get(x, y);
      samples.add(new ColorSample(red(c), green(c), blue(c)));
    }

    return samples;
  }

  ArrayList<ColorSample> performKMeansClustering(ArrayList<ColorSample> samples) {
    int k = config.colorPalette;
    ArrayList<ColorSample> centroids = new ArrayList<ColorSample>();

    // Initialize random centroids from samples
    for (int i = 0; i < k; i++) {
      int randomIndex = floor(random(samples.size()));
      ColorSample sample = samples.get(randomIndex);
      centroids.add(new ColorSample(sample.r, sample.g, sample.b));
    }

    // Perform k-means iterations
    for (int iter = 0; iter < 5; iter++) {
      // Create clusters
      ArrayList<ArrayList<ColorSample>> clusters = new ArrayList<ArrayList<ColorSample>>();
      for (int i = 0; i < k; i++) {
        clusters.add(new ArrayList<ColorSample>());
      }

      // Assign samples to nearest centroid
      for (ColorSample sample : samples) {
        int nearestCentroidIndex = findNearestCentroid(sample, centroids);
        clusters.get(nearestCentroidIndex).add(sample);
      }

      // Update centroids
      for (int i = 0; i < k; i++) {
        ArrayList<ColorSample> cluster = clusters.get(i);
        if (cluster.size() > 0) {
          updateCentroid(centroids.get(i), cluster);
        }
      }
    }

    return centroids;
  }

  int findNearestCentroid(ColorSample sample, ArrayList<ColorSample> centroids) {
    float minDist = Float.MAX_VALUE;
    int nearest = 0;

    for (int i = 0; i < centroids.size(); i++) {
      float dist = sample.distanceTo(centroids.get(i));
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }

    return nearest;
  }

  void updateCentroid(ColorSample centroid, ArrayList<ColorSample> cluster) {
    float sumR = 0, sumG = 0, sumB = 0;
    for (ColorSample sample : cluster) {
      sumR += sample.r;
      sumG += sample.g;
      sumB += sample.b;
    }

    centroid.r = sumR / cluster.size();
    centroid.g = sumG / cluster.size();
    centroid.b = sumB / cluster.size();
  }

  float colorDistance(ColorSample color1, ColorSample color2) {
    return color1.distanceTo(color2);
  }

  float getLocalContrast(int x, int y) {
    if (brightnessMap == null) return 0;

    // Sample a small region around the point
    final int radius = 5;
    ArrayList<Float> samples = new ArrayList<Float>();

    for (int dx = -radius; dx <= radius; dx += 2) {
      for (int dy = -radius; dy <= radius; dy += 2) {
        int sx = constrain(x + dx, 0, sourceImage.width - 1);
        int sy = constrain(y + dy, 0, sourceImage.height - 1);
        samples.add(red(brightnessMap.get(sx, sy)));
      }
    }

    // Calculate standard deviation as a measure of contrast
    float mean = calculateMean(samples);
    float variance = calculateVariance(samples, mean);

    return sqrt(variance) / 255; // Normalized contrast value
  }

  float calculateMean(ArrayList<Float> values) {
    float sum = 0;
    for (float val : values) {
      sum += val;
    }
    return sum / values.size();
  }

  float calculateVariance(ArrayList<Float> values, float mean) {
    float sum = 0;
    for (float val : values) {
      sum += sq(val - mean);
    }
    return sum / values.size();
  }

  float getEdgeAngle(int x, int y) {
    if (edgeMap == null) return 0;

    // Estimate edge direction by sampling neighboring pixels
    final int radius = 2;
    float edgeX = 0;
    float edgeY = 0;

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue;

        int sx = constrain(x + dx, 0, edgeMap.width - 1);
        int sy = constrain(y + dy, 0, edgeMap.height - 1);

        float edgeValue = red(edgeMap.get(sx, sy));
        if (edgeValue > 200) {
          edgeX += dx;
          edgeY += dy;
        }
      }
    }

    if (edgeX == 0 && edgeY == 0) return 0;
    return atan2(edgeY, edgeX) + PI / 2; // Rotate 90 degrees to get edge direction
  }

  float angleDistance(float angle1, float angle2) {
    // Calculate smallest angular distance
    float diff = (angle2 - angle1) % TWO_PI;
    if (diff > PI) diff -= TWO_PI;
    if (diff < -PI) diff += TWO_PI;
    return diff;
  }
}


class ColorSample {
  float r, g, b;

  ColorSample(float r, float g, float b) {
    this.r = r;
    this.g = g;
    this.b = b;
  }

  // Non-static helper methods are fine
  color toColor(int alpha) {
    return color(r, g, b, alpha);
  }

  float distanceTo(ColorSample other) {
    return sqrt(
      sq(r - other.r) +
      sq(g - other.g) +
      sq(b - other.b)
      );
  }
}
