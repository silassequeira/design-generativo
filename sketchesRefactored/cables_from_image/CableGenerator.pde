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

    println("Planning cables...");

    HashSet<String> attemptedConnections = new HashSet<String>();
    int cablesPlanned = 0;
    int attempts = 0;
    final int maxAttempts = 7000;

    while (cablesPlanned < config.cableCount && attempts < maxAttempts) {
      attempts++;

      // Find available jacks
      ArrayList<Jack> availableJacks = getAvailableJacks();
      if (availableJacks.size() < 2) break;

      Jack startJack = availableJacks.get(floor(random(availableJacks.size())));

      // Find potential target jacks
      ArrayList<Jack> potentialTargets = findPotentialTargets(startJack, availableJacks, attemptedConnections);
      if (potentialTargets.size() == 0) continue;

      // Find best target
      Jack bestTarget = findBestTarget(startJack, potentialTargets);

      // Create cable and update connections
      Cable newCable = createCable(startJack, bestTarget);
      if (newCable != null) {
        pendingCables.add(newCable);
        startJack.connect();
        bestTarget.connect();
        cablesPlanned++;
      }
    }

    // Sort cables by importance for progressive rendering
    pendingCables.sort(new CableComparator());
    println("Planned " + cablesPlanned + " cables after " + attempts + " attempts");
  }

  ArrayList<Jack> getAvailableJacks() {
    ArrayList<Jack> available = new ArrayList<Jack>();
    for (Jack jack : jackManager.jacks) {
      if (jack.connections < config.maxConnectionsPerJack) {
        available.add(jack);
      }
    }
    return available;
  }

  ArrayList<Jack> findPotentialTargets(Jack startJack, ArrayList<Jack> availableJacks,
    HashSet<String> attemptedConnections) {
    ArrayList<Jack> targets = new ArrayList<Jack>();

    for (Jack jack : availableJacks) {
      if (jack.id == startJack.id) continue;

      float distance = dist(startJack.x, startJack.y, jack.x, jack.y);

      // Check if connection already attempted
      String connectionKey = min(startJack.id, jack.id) + "-" + max(startJack.id, jack.id);
      if (attemptedConnections.contains(connectionKey)) continue;

      // Add to attempted connections
      attemptedConnections.add(connectionKey);

      // Check distance constraints
      if (distance >= config.minCableLength && distance <= config.maxCableLength) {
        targets.add(jack);
      }
    }

    return targets;
  }

  Jack findBestTarget(Jack startJack, ArrayList<Jack> targets) {
    Jack bestTarget = targets.get(0);
    float bestScore = -1;

    // Evaluate at most 10 targets for performance
    for (int i = 0; i < min(targets.size(), 10); i++) {
      Jack target = targets.get(i);
      float score = evaluateConnectionQuality(startJack, target);

      if (score > bestScore) {
        bestScore = score;
        bestTarget = target;
      }
    }

    return bestTarget;
  }

  float evaluateConnectionQuality(Jack jack1, Jack jack2) {
    if (imageAnalyzer.sourceImage == null) return 0;

    // Sample along the potential path
    final int samples = config.colorSamples;
    float colorVariance = 0;
    float edgeFollowing = 0;
    int previousColor = color(0);
    boolean firstSample = true;
    ArrayList<Integer> sampleColors = new ArrayList<Integer>();

    // Get angle of connection
    float angle = atan2(jack2.y - jack1.y, jack2.x - jack1.x);

    // Sample points along the line
    for (int i = 0; i <= samples; i++) {
      float t = i / float(samples);
      int x = floor(lerp(jack1.x, jack2.x, t));
      int y = floor(lerp(jack1.y, jack2.y, t));

      // Constrain to image bounds
      x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
      y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);

      // Sample color
      int imgColor = imageAnalyzer.sourceImage.get(x, y);
      sampleColors.add(imgColor);

      // Check if on edge
      float edgeValue = red(imageAnalyzer.edgeMap.get(x, y));
      if (edgeValue > 200) {
        edgeFollowing += evaluateEdgeAlignment(x, y, angle);
      }

      if (!firstSample) {
        colorVariance += calculateColorDifference(previousColor, imgColor);
      }

      previousColor = imgColor;
      firstSample = false;
    }

    // Calculate scores
    float avgVariance = colorVariance / samples;
    float edgeScore = (edgeFollowing / samples) * config.edgePreference * 15;
    float totalBrightness = calculateTotalBrightness(sampleColors);
    float avgBrightness = totalBrightness / sampleColors.size();

    // Final score components
    float colorConsistencyScore = map(avgVariance, 0, 100, 10, 0);
    float brightnessScore = map(abs(avgBrightness - 128), 0, 128, 5, 0);

    return colorConsistencyScore + brightnessScore + edgeScore;
  }

  float evaluateEdgeAlignment(int x, int y, float lineAngle) {
    float score = 1.0;

    // Check if line direction matches edge direction
    float edgeAngle = imageAnalyzer.getEdgeAngle(x, y);
    float angleDiff = abs(imageAnalyzer.angleDistance(lineAngle, edgeAngle));

    // If line is parallel to edge, give extra points
    if (angleDiff < PI / 4) {
      score += 0.5;
    }

    return score;
  }

  float calculateColorDifference(int color1, int color2) {
    float r1 = red(color1);
    float g1 = green(color1);
    float b1 = blue(color1);

    float r2 = red(color2);
    float g2 = green(color2);
    float b2 = blue(color2);

    return sqrt(sq(r2 - r1) + sq(g2 - g1) + sq(b2 - b1));
  }

  float calculateTotalBrightness(ArrayList<Integer> colors) {
    float total = 0;
    for (int c : colors) {
      total += (red(c) + green(c) + blue(c)) / 3;
    }
    return total;
  }

  Cable createCable(Jack startJack, Jack endJack) {
    if (imageAnalyzer.sourceImage == null) {
      return null;
    }

    try {
      // Sample colors along the path
      final int samples = 8;
      ArrayList<ColorSample> sampleColors = sampleColorsAlongPath(startJack, endJack, samples);

      // Calculate average color
      ColorSample avgColor = calculateAverageColor(sampleColors);

      // Find closest cluster color
      color cableColor = findClosestClusterColor(avgColor);

      // Calculate importance score for rendering order
      float importance = calculateImportance(startJack, endJack, samples);

      // Create and return cable
      Cable cable = new Cable();
      cable.start = startJack.id;
      cable.end = endJack.id;
      cable.cableColor = cableColor;
      cable.startPoint = new PVector(startJack.x, startJack.y);
      cable.endPoint = new PVector(endJack.x, endJack.y);
      cable.importance = importance;

      return cable;
    }
    catch (Exception e) {
      println("Error creating cable: " + e.getMessage());

      // Return a basic cable on error
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

  ArrayList<ColorSample> sampleColorsAlongPath(Jack jack1, Jack jack2, int sampleCount) {
    ArrayList<ColorSample> samples = new ArrayList<ColorSample>();

    for (int i = 0; i <= sampleCount; i++) {
      float t = i / float(sampleCount);
      int x = floor(lerp(jack1.x, jack2.x, t));
      int y = floor(lerp(jack1.y, jack2.y, t));

      // Constrain to image bounds
      x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
      y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);

      // Sample color
      int imgColor = imageAnalyzer.sourceImage.get(x, y);
      samples.add(new ColorSample(red(imgColor), green(imgColor), blue(imgColor)));
    }

    return samples;
  }

  ColorSample calculateAverageColor(ArrayList<ColorSample> samples) {
    float r = 0, g = 0, b = 0;
    for (ColorSample c : samples) {
      r += c.r;
      g += c.g;
      b += c.b;
    }
    return new ColorSample(
      r / samples.size(),
      g / samples.size(),
      b / samples.size()
      );
  }

  color findClosestClusterColor(ColorSample targetColor) {
    if (imageAnalyzer.colorClusters == null || imageAnalyzer.colorClusters.size() == 0) {
      return color(200); // Default if no clusters
    }

    int closestIndex = 0;
    float minDistance = Float.MAX_VALUE;

    for (int i = 0; i < imageAnalyzer.colorClusters.size(); i++) {
      color clusterColor = imageAnalyzer.colorClusters.get(i);
      ColorSample clusterSample = new ColorSample(
        red(clusterColor),
        green(clusterColor),
        blue(clusterColor)
        );
      float dist = targetColor.distanceTo(clusterSample);

      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    return imageAnalyzer.colorClusters.get(closestIndex);
  }

  float calculateImportance(Jack jack1, Jack jack2, int sampleCount) {
    // Longer lines and edge-following lines are more important
    float length = dist(jack1.x, jack1.y, jack2.x, jack2.y);
    float edgeScore = 0;

    // Check if line follows edges
    for (int i = 0; i <= sampleCount; i++) {
      float t = i / float(sampleCount);
      int x = floor(lerp(jack1.x, jack2.x, t));
      int y = floor(lerp(jack1.y, jack2.y, t));

      x = constrain(x, 0, imageAnalyzer.sourceImage.width - 1);
      y = constrain(y, 0, imageAnalyzer.sourceImage.height - 1);

      if (imageAnalyzer.edgeMap != null && red(imageAnalyzer.edgeMap.get(x, y)) > 200) {
        edgeScore++;
      }
    }

    return (length / config.maxCableLength) * 5 + (edgeScore / sampleCount) * 10;
  }

  boolean addCablesProgressively() {
    if (config.progressiveRendering && pendingCables.size() > 0) {
      // Add a few cables each frame
      int countToAdd = min(config.cablesPerFrame, pendingCables.size());

      for (int i = 0; i < countToAdd; i++) {
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
    for (Cable cable : cables) {
      cable.draw(config);
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


class Cable {
  int start;
  int end;
  color cableColor;
  PVector startPoint;
  PVector endPoint;
  float importance;

  Cable() {
    // Default constructor
  }

  Cable(Jack startJack, Jack endJack, color cableColor) {
    this.start = startJack.id;
    this.end = endJack.id;
    this.cableColor = cableColor;
    this.startPoint = new PVector(startJack.x, startJack.y);
    this.endPoint = new PVector(endJack.x, endJack.y);
    this.importance = 0;
  }

  void draw(Config config) {
    stroke(cableColor);
    strokeWeight(config.cableThickness);
    line(startPoint.x, startPoint.y, endPoint.x, endPoint.y);
  }
}

class CableComparator implements java.util.Comparator<Cable> {
  int compare(Cable a, Cable b) {
    return Float.compare(b.importance, a.importance);
  }
}
