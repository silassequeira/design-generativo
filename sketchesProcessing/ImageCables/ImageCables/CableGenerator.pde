import java.util.HashSet;
import java.util.ArrayList;

class CableGenerator {
  Config config;
  ImageAnalyzer imageAnalyzer;
  JackManager jackManager;
  
  ArrayList<Cable> cables;
  ArrayList<Cable> pendingCables;
  int buildProgress;
  
  CableGenerator(Config config, ImageAnalyzer imageAnalyzer, JackManager jackManager) {
    this.config = config;
    this.imageAnalyzer = imageAnalyzer;
    this.jackManager = jackManager;
    
    this.cables = new ArrayList<Cable>();
    this.pendingCables = new ArrayList<Cable>();
    this.buildProgress = 0;
  }
  
  void planCablesFromImage() {
    cables.clear();
    pendingCables.clear();
    buildProgress = 0;
    
    if (!imageAnalyzer.imageLoaded) return;
    
    ArrayList<Jack> jackPoints = jackManager.jacks;
    HashSet<String> attemptedConnections = new HashSet<String>(); // Track attempted connections
    
    println("Planning cables...");
    
    // Create cables that represent the image
    int cablesPlanned = 0;
    int attempts = 0;
    final int maxAttempts = 7000; // More attempts for better quality
    
    // Keep trying until we have enough planned cables or run out of attempts
    while (cablesPlanned < config.cableCount && attempts < maxAttempts) {
      attempts++;
      
      // Find jacks that aren't already connected too many times
      ArrayList<Jack> availableJacks = new ArrayList<Jack>();
      for (Jack jack : jackPoints) {
        if (jack.connections < config.maxConnectionsPerJack) {
          availableJacks.add(jack);
        }
      }
      
      if (availableJacks.size() < 2) break;
      
      Jack startJack = availableJacks.get(floor(random(availableJacks.size())));
      
      // Find potential target jacks within distance limits
      ArrayList<Jack> potentialTargets = new ArrayList<Jack>();
      for (Jack jack : availableJacks) {
        if (jack.id == startJack.id) continue;
        
        // Calculate distance between jacks
        float distance = dist(startJack.x, startJack.y, jack.x, jack.y);
        
        // Check if connection already attempted
        String connectionKey = min(startJack.id, jack.id) + "-" + max(startJack.id, jack.id);
        if (attemptedConnections.contains(connectionKey)) continue;
        
        // Add to attempted connections
        attemptedConnections.add(connectionKey);
        
        // Check distance constraints
        if (distance >= config.minCableLength && distance <= config.maxCableLength) {
          potentialTargets.add(jack);
        }
      }
      
      if (potentialTargets.size() == 0) continue;
      
      // Find a target that best represents the image
      int bestTargetIndex = 0;
      float bestTargetScore = -1;
      
      for (int i = 0; i < min(potentialTargets.size(), 10); i++) {
        Jack targetJack = potentialTargets.get(i);
        float score = evaluateConnectionQuality(startJack, targetJack);
        
        if (score > bestTargetScore) {
          bestTargetScore = score;
          bestTargetIndex = i;
        }
      }
      
      if (bestTargetScore > 0) {
        Jack bestTarget = potentialTargets.get(bestTargetIndex);
        
        // Create the cable and add to pending list
        Cable newCable = createCable(startJack, bestTarget);
        pendingCables.add(newCable);
        
        // Update connection count for both jacks
        startJack.connections++;
        bestTarget.connections++;
        
        cablesPlanned++;
      }
    }
    
    // Sort cables by their visual importance
    pendingCables.sort(new CableComparator());
    
    println("Planned " + cablesPlanned + " cables after " + attempts + " attempts");
  }
  
  float evaluateConnectionQuality(Jack jack1, Jack jack2) {
    if (imageAnalyzer.sourceImage == null) return 0;
    
    // Sample colors and edges along the potential cable path
    final int samples = config.colorSamples;
    float colorVariance = 0;
    float edgeFollowing = 0;
    int previousColor = color(0);
    boolean firstSample = true;
    ArrayList<Integer> sampleColors = new ArrayList<Integer>();
    
    // Get angle of connection
    float angle = atan2(jack2.y - jack1.y, jack2.x - jack1.x);
    
    // Sample colors and edges along the line
    for (int i = 0; i <= samples; i++) {
      float t = i / float(samples);
      int x = floor(lerp(jack1.x, jack2.x, t));
      int y = floor(lerp(jack1.y, jack2.y, t));
      
      // Constrain to image bounds
      x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
      y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);
      
      // Sample colors
      int imgColor = imageAnalyzer.sourceImage.get(x, y);
      sampleColors.add(imgColor);
      
      // Check if on edge
      float edgeValue = red(imageAnalyzer.edgeMap.get(x, y));
      if (edgeValue > 200) {
        edgeFollowing++;
        
        // Extra bonus if the line follows an edge
        if (i > 0 && i < samples) {
          // Check if the edge direction matches the line
          float edgeAngle = imageAnalyzer.getEdgeAngle(x, y);
          float angleDiff = abs(imageAnalyzer.angleDistance(angle, edgeAngle));
          
          // If line is parallel to edge, give extra points
          if (angleDiff < PI / 4) {
            edgeFollowing += 0.5;
          }
        }
      }
      
      if (!firstSample) {
        // Calculate color difference from previous sample
        float r1 = red(previousColor);
        float g1 = green(previousColor);
        float b1 = blue(previousColor);
        
        float r2 = red(imgColor);
        float g2 = green(imgColor);
        float b2 = blue(imgColor);
        
        // Simple color distance formula
        float colorDiff = sqrt(sq(r2 - r1) + sq(g2 - g1) + sq(b2 - b1));
        colorVariance += colorDiff;
      }
      
      previousColor = imgColor;
      firstSample = false;
    }
    
    // Calculate average color variance
    float avgVariance = colorVariance / samples;
    
    // Calculate edge following score
    float edgeScore = (edgeFollowing / samples) * config.edgePreference * 15;
    
    // Calculate overall brightness of the line
    float totalBrightness = 0;
    for (int c : sampleColors) {
      totalBrightness += (red(c) + green(c) + blue(c)) / 3;
    }
    float avgBrightness = totalBrightness / sampleColors.size();
    
    // Score components:
    // 1. Color variance - lower is better (consistent color)
    // 2. Edge following - higher is better
    // 3. Brightness - middle range is better
    float colorConsistencyScore = map(avgVariance, 0, 100, 10, 0);
    float brightnessScore = map(abs(avgBrightness - 128), 0, 128, 5, 0);
    
    float totalScore = colorConsistencyScore + brightnessScore + edgeScore;
    
    return totalScore;
  }
  
  Cable createCable(Jack startJack, Jack endJack) {
    if (imageAnalyzer.sourceImage == null) {
      return null;
    }
    
    if (imageAnalyzer.colorClusters == null || imageAnalyzer.colorClusters.size() == 0) {
      // Handle case where color clusters aren't available
      println("Warning: No color clusters available");
      Cable cable = new Cable();
      cable.start = startJack.id;
      cable.end = endJack.id;
      cable.cableColor = color(200);  // Default gray
      cable.startPoint = new PVector(startJack.x, startJack.y);
      cable.endPoint = new PVector(endJack.x, endJack.y);
      cable.importance = 0;
      return cable;
    }
    
    try {
      // Sample colors along the path to determine best color
      final int samples = 8;
      ArrayList<ColorSample> sampleColors = new ArrayList<ColorSample>();
      
      // Sample multiple points to get colors
      for (int i = 0; i <= samples; i++) {
        float t = i / float(samples);
        int x = floor(lerp(startJack.x, startJack.x, t));
        int y = floor(lerp(startJack.y, endJack.y, t));
        
        // Constrain to image bounds
        x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
        y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);
        
        // Get image color at this point
        int imgColor = imageAnalyzer.sourceImage.get(x, y);
        sampleColors.add(new ColorSample(red(imgColor), green(imgColor), blue(imgColor)));
      }
      
      // Calculate average color
      float r = 0, g = 0, b = 0;
      for (ColorSample c : sampleColors) {
        r += c.r;
        g += c.g;
        b += c.b;
      }
      r = r / sampleColors.size();
      g = g / sampleColors.size();
      b = b / sampleColors.size();
      
      // Find the closest color cluster
      ColorSample avgColor = new ColorSample(r, g, b);
      int closestClusterIndex = 0;
      float minDistance = Float.MAX_VALUE;
      
      for (int i = 0; i < imageAnalyzer.colorClusters.size(); i++) {
        int clusterColor = imageAnalyzer.colorClusters.get(i);
        float dist = imageAnalyzer.colorDistance(
          avgColor, 
          new ColorSample(red(clusterColor), green(clusterColor), blue(clusterColor))
        );
        
        if (dist < minDistance) {
          minDistance = dist;
          closestClusterIndex = i;
        }
      }
      
      // Calculate importance score - used for rendering order
      // Longer lines, lines on edges, and lines with distinct colors are more important
      float length = dist(startJack.x, startJack.y, endJack.x, endJack.y);
      float edgeScore = 0;
      
      // Check if the line follows edges
      for (int i = 0; i <= samples; i++) {
        float t = i / float(samples);
        int x = floor(lerp(startJack.x, endJack.x, t)); // Fixed this line - was duplicating x
        int y = floor(lerp(startJack.y, endJack.y, t));
        x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
        y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);
        
        if (imageAnalyzer.edgeMap != null && red(imageAnalyzer.edgeMap.get(x, y)) > 200) {
          edgeScore += 1;
        }
      }
      
      float importance = (length / config.maxCableLength) * 5 + (edgeScore / samples) * 10;
      
      // Create cable with the chosen cluster color
      Cable cable = new Cable();
      cable.start = startJack.id;
      cable.end = endJack.id;
      cable.cableColor = imageAnalyzer.colorClusters.get(closestClusterIndex);
      cable.startPoint = new PVector(startJack.x, startJack.y);
      cable.endPoint = new PVector(endJack.x, endJack.y);
      cable.importance = importance;
      
      return cable;
    } catch (Exception e) {
      println("Error creating cable: " + e.getMessage());
      e.printStackTrace();
      
      // Return a default cable on error
      Cable cable = new Cable();
      cable.start = startJack.id;
      cable.end = endJack.id;
      cable.cableColor = color(200);
      cable.startPoint = new PVector(startJack.x, startJack.y);
      cable.endPoint = new PVector(endJack.x, endJack.y);
      cable.importance = 0;
      return cable;
    }
  }
  
  boolean addCablesProgressively() {
    if (config.progressiveRendering && pendingCables.size() > 0) {
      // Add a few cables each frame
      for (int i = 0; i < config.cablesPerFrame && pendingCables.size() > 0; i++) {
        cables.add(pendingCables.get(0));
        pendingCables.remove(0);
        buildProgress++;
      }
      return true;
    }
    return false;
  }
  
  void addAllCablesImmediately() {
    cables.addAll(pendingCables);
    buildProgress += pendingCables.size();
    pendingCables.clear();
  }
  
  void drawCables() {
    // Draw each cable as a simple line with its color
    for (Cable cable : cables) {
      stroke(cable.cableColor);
      strokeWeight(config.cableThickness);
      line(
        cable.startPoint.x, cable.startPoint.y,
        cable.endPoint.x, cable.endPoint.y
      );
    }
  }
  
  float getProgress() {
    final int total = buildProgress + pendingCables.size();
    if (total == 0) return 100;
    return (buildProgress / float(total)) * 100;
  }
  
  void reset() {
    cables.clear();
    pendingCables.clear();
    buildProgress = 0;
  }
}

// Cable representation class
class Cable {
  int start;
  int end;
  int cableColor;  // Changed from "color" to "cableColor" to avoid reserved keyword
  PVector startPoint;
  PVector endPoint;
  float importance;
}

// Comparator for sorting cables by importance
class CableComparator implements java.util.Comparator<Cable> {
  int compare(Cable a, Cable b) {
    return Float.compare(b.importance, a.importance);
  }
}
