class PointWithRadius {
  
  private final String code;
  private final float x;
  private final float y;
  private final float radius;
  
  public PointWithRadius(String newCode, float newX, float newY, float newRadius) {
    code = newCode;
    x = newX;
    y = newY;
    radius = newRadius;
  }
  
  public String getCode() {
    return code;
  }
  
  public float getX() {
    return x;
  }
  
  public float getY() {
    return y;
  }
  
  public float getRadius() {
    return radius;
  }
  
}


PointWithRadius makePointWithRadius(Station station) {
  GeoPoint point = new GeoPoint(station.getLongitude(), station.getLatitude());
  
  String code = station.getCode();
  float x = point.getX(mapView);
  float y = point.getY(mapView);
  float radius = getHaloRadius(station.getCount());
  
  return new PointWithRadius(code, x, y, radius);
}


Map<String, PointWithRadius> getStationLocations() {
  return dataset.getStations()
    .stream()
    .map((x) -> makePointWithRadius(x))
    .collect(Collectors.toMap(
      (x) -> x.getCode(),
      (x) -> x
    ));
}


Set<String> getHighlightedCodes() {
  PVector mousePosition = new PVector(mouseX, mouseY);
  
  return getStationLocations().values().stream()
    .filter((point) -> {
      PVector position = new PVector(point.getX(), point.getY());
      float distance = position.dist(mousePosition);
      boolean hovering = distance <= point.getRadius();
      return hovering;
    })
    .map((x) -> x.getCode())
    .collect(Collectors.toSet());
}


void drawStationsAndEdges(Set<String> highlightedCodes) {
  drawEdges(highlightedCodes);
  drawStations(highlightedCodes);
}


void drawStations(Set<String> highlightedCodes) {
  pushMatrix();
  pushStyle();
  
  noStroke();
  ellipseMode(RADIUS);
  
  boolean hasHighlight = !highlightedCodes.isEmpty();
  
  for (Station station : dataset.getStations()) {
    PointWithRadius pointWithRadius = makePointWithRadius(station);
    
    float x = pointWithRadius.getX();
    float y = pointWithRadius.getY();
    
    String stationCode = station.getCode();
    boolean hovering = highlightedCodes.contains(stationCode);
    
    // Overlap halo
    if (hasHighlight) {
      float overlapCount = dataset.getStations().stream()
        .flatMap((target) -> target.getEdges().stream())
        .filter((target) -> target.contains(stationCode))
        .filter((target) -> highlightedCodes.contains(target.getOther(stationCode)))
        .map((target) -> target.getCount())
        .reduce((a, b) -> a + b)
        .orElse(0.0);
      
      fill(OVERLAP_COLOR);
      noStroke();
      
      float highlightRadius = getHaloRadius(overlapCount);
      ellipse(x, y, highlightRadius, highlightRadius);
    }
    
    // Halo
    fill(hovering ? HALO_CENTER_COLOR_ACTIVE : HALO_CENTER_COLOR_INACTIVE);
    stroke(HALO_BORDER);
    float radius = pointWithRadius.getRadius();
    ellipse(x, y, radius, radius);
  }
  
  popStyle();
  popMatrix();
}


void drawEdges(Set<String> highlightedCodes) {
  pushMatrix();
  pushStyle();
  
  noStroke();
  ellipseMode(RADIUS);
  
  Map<String, PointWithRadius> stationLocations = getStationLocations();
  
  boolean nothingHighlighted = highlightedCodes.isEmpty();
  
  noFill();
  
  dataset.getStations()
    .stream()
    .flatMap((x) -> x.getEdges().stream())
    .forEach((edge) -> {
      PointWithRadius start = stationLocations.get(edge.getSource());
      PointWithRadius end = stationLocations.get(edge.getDestination());
      
      boolean hoveringStart = highlightedCodes.contains(edge.getSource());
      boolean hoveringEnd = highlightedCodes.contains(edge.getDestination());
      boolean hovering = hoveringStart || hoveringEnd;
      stroke(hovering ? EDGE_COLOR_ACTIVE : EDGE_COLOR_INACTIVE);
      
      if (hovering || nothingHighlighted) {
        strokeWeight(getEdgeWidth(edge.getCount()));
        line(start.getX(), start.getY(), end.getX(), end.getY());
      }
    });
  
  popStyle();
  popMatrix();
  
}
