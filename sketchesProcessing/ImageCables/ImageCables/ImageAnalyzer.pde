class ImageAnalyzer {
  Config config;
  PImage sourceImage;
  PGraphics edgeMap;
  PGraphics brightnessMap;
  ArrayList<Integer> colorClusters;
  boolean imageLoaded;
  PApplet sketch; // Reference to the main sketch
  
  ImageAnalyzer(Config config, PApplet sketch) {
    this.config = config;
    this.sketch = sketch; // Store the reference
    this.colorClusters = new ArrayList<Integer>();
    this.imageLoaded = false;
  }
  
  void loadImage(String path) {
    try {
      // Use the sketch reference to call loadImage
      sourceImage = sketch.loadImage(path);
      
      if (sourceImage != null) {
        imageLoaded = true;
        println("Image loaded successfully");
      } else {
        println("Failed to load image");
      }
    } catch (Exception e) {
      println("Error loading image: " + e.getMessage());
      imageLoaded = false;
    }
  }
  
  void resizeImage(int width, int height) {
    if (sourceImage != null) {
      if (width > 0 && height > 0) {  // Add dimension check
        sourceImage.resize(width, height);
      } else {
        println("Error: Invalid dimensions for resize (" + width + "x" + height + ")");
      }
    }
  }
  
  void analyzeImage() {
    if (!imageLoaded || sourceImage == null) return;
    if (sourceImage.width <= 0 || sourceImage.height <= 0) {
      println("Error: Invalid image dimensions (" + sourceImage.width + "x" + sourceImage.height + ")");
      return;
    }
    
    println("Analyzing image...");
    
    // Create the edge and brightness maps with size checks
    try {
      edgeMap = createGraphics(sourceImage.width, sourceImage.height);
      brightnessMap = createGraphics(sourceImage.width, sourceImage.height);
      
      // Draw the source image to both graphics buffers
      edgeMap.beginDraw();
      edgeMap.image(sourceImage, 0, 0);
      edgeMap.endDraw();
      
      brightnessMap.beginDraw();
      brightnessMap.image(sourceImage, 0, 0);
      brightnessMap.endDraw();
      
      // Process the brightness map
      brightnessMap.loadPixels();
      for (int i = 0; i < brightnessMap.pixels.length; i++) {
        int c = brightnessMap.pixels[i];
        float r = red(c);
        float g = green(c);
        float b = blue(c);
        float brightness = (r + g + b) / 3;
        
        // Set all channels to brightness value for easier reading later
        brightnessMap.pixels[i] = color(brightness, brightness, brightness);
      }
      brightnessMap.updatePixels();
      
      // Process the edge map - use a more sophisticated edge detection
      edgeMap.beginDraw();
      edgeMap.filter(GRAY);
      edgeMap.endDraw();
      
      // Create a temporary graphics buffer for edge detection
      PGraphics edgeTemp = createGraphics(edgeMap.width, edgeMap.height);
      edgeTemp.beginDraw();
      edgeTemp.image(edgeMap, 0, 0);
      edgeTemp.endDraw();
      
      // Apply more sophisticated edge detection
      edgeMap.loadPixels();
      edgeTemp.loadPixels();
      
      // Simple Sobel-like edge detection
      for (int x = 1; x < edgeMap.width - 1; x++) {
        for (int y = 1; y < edgeMap.height - 1; y++) {
          // Get surrounding pixels
          float pixNW = brightness(edgeTemp.get(x - 1, y - 1));
          float pixN = brightness(edgeTemp.get(x, y - 1));
          float pixNE = brightness(edgeTemp.get(x + 1, y - 1));
          float pixW = brightness(edgeTemp.get(x - 1, y));
          float pixE = brightness(edgeTemp.get(x + 1, y));
          float pixSW = brightness(edgeTemp.get(x - 1, y + 1));
          float pixS = brightness(edgeTemp.get(x, y + 1));
          float pixSE = brightness(edgeTemp.get(x + 1, y + 1));
          
          // Horizontal and vertical gradient approximations
          float pixH = (pixNW + pixW + pixSW) - (pixNE + pixE + pixSE);
          float pixV = (pixNW + pixN + pixNE) - (pixSW + pixS + pixSE);
          
          // Gradient magnitude
          float edgeStrength = sqrt(pixH * pixH + pixV * pixV);
          
          // Apply threshold
          int edgePixel = edgeStrength > config.edgeThreshold ? 255 : 0;
          
          // Set pixel in edge map
          int idx = y * edgeMap.width + x;
          edgeMap.pixels[idx] = color(edgePixel, edgePixel, edgePixel);
        }
      }
      
      edgeMap.updatePixels();
      
      println("Image analysis complete.");
    } catch (Exception e) {
      println("Error during image analysis: " + e.getMessage());
    }
  }
  
  void generateColorClusters() {
    if (!imageLoaded || sourceImage == null) return;
    
    println("Generating color clusters...");
    
    try {
      // Sample colors from the image
      int sampleCount = 2000; // Number of random sample points
      ArrayList<ColorSample> colorSamples = new ArrayList<ColorSample>();
      
      // Take random samples from the image
      for (int i = 0; i < sampleCount; i++) {
        int x = floor(random(sourceImage.width));
        int y = floor(random(sourceImage.height));
        int c = sourceImage.get(x, y);
        colorSamples.add(new ColorSample(red(c), green(c), blue(c)));
      }
      
      // Simple k-means clustering
      int k = config.colorPalette; // Number of clusters
      ArrayList<ColorSample> centroids = new ArrayList<ColorSample>();
      
      // Initialize random centroids from the samples
      for (int i = 0; i < k; i++) {
        int randomIndex = floor(random(colorSamples.size()));
        ColorSample sample = colorSamples.get(randomIndex);
        centroids.add(new ColorSample(sample.r, sample.g, sample.b));
      }
      
      // Run k-means for a fixed number of iterations
      int iterations = 5;
      for (int iter = 0; iter < iterations; iter++) {
        // Assign each sample to the nearest centroid
        ArrayList<ArrayList<ColorSample>> clusters = new ArrayList<ArrayList<ColorSample>>();
        for (int i = 0; i < k; i++) {
          clusters.add(new ArrayList<ColorSample>());
        }
        
        for (ColorSample sample : colorSamples) {
          float minDist = Float.MAX_VALUE;
          int clusterIndex = 0;
          
          for (int j = 0; j < k; j++) {
            ColorSample centroid = centroids.get(j);
            float dist = colorDistance(sample, centroid);
            if (dist < minDist) {
              minDist = dist;
              clusterIndex = j;
            }
          }
          
          clusters.get(clusterIndex).add(sample);
        }
        
        // Update centroids
        for (int i = 0; i < k; i++) {
          ArrayList<ColorSample> cluster = clusters.get(i);
          if (cluster.size() > 0) {
            float sumR = 0, sumG = 0, sumB = 0;
            for (ColorSample sample : cluster) {
              sumR += sample.r;
              sumG += sample.g;
              sumB += sample.b;
            }
            
            centroids.get(i).r = sumR / cluster.size();
            centroids.get(i).g = sumG / cluster.size();
            centroids.get(i).b = sumB / cluster.size();
          }
        }
      }
      
      // Save the clusters for later use
      colorClusters.clear();
      for (ColorSample c : centroids) {
        colorClusters.add(color(c.r, c.g, c.b, config.alpha));
      }
      
      println("Generated " + colorClusters.size() + " color clusters");
    } catch (Exception e) {
      println("Error generating color clusters: " + e.getMessage());
      e.printStackTrace();
    }
  }
  
  float colorDistance(ColorSample color1, ColorSample color2) {
    // Simple Euclidean distance in RGB space
    return sqrt(
      sq(color1.r - color2.r) +
      sq(color1.g - color2.g) +
      sq(color1.b - color2.b)
    );
  }
  
  float getLocalContrast(int x, int y) {
    if (brightnessMap == null) return 0;
    
    // Sample a small region around the point to determine local contrast
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
    float mean = 0;
    for (float val : samples) {
      mean += val;
    }
    mean /= samples.size();
    
    float variance = 0;
    for (float val : samples) {
      variance += sq(val - mean);
    }
    variance /= samples.size();
    
    return sqrt(variance) / 255; // Normalized contrast value (0-1)
  }
  
  float getEdgeAngle(int x, int y) {
    if (edgeMap == null) return 0;
    
    // Simple estimate of edge direction by sampling neighboring pixels
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
    // Calculate the smallest angular distance between two angles
    float diff = (angle2 - angle1) % TWO_PI;
    if (diff > PI) diff -= TWO_PI;
    if (diff < -PI) diff += TWO_PI;
    return diff;
  }
}

// Helper class for color operations
class ColorSample {
  float r, g, b;
  
  ColorSample(float r, float g, float b) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}
