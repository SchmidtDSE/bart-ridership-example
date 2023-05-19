/**
 * Logic for stations and the journies between them in the BART viz.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of processing-geopoint released under the BSD 3-Clause License. See
 * LICENSE.md.
 *
 * @license BSD
 */


/**
 * Record describing how to draw a station's glyph (ellipse).
 *
 * Record describing a point with a halo radius which can be used to describe a
 * station with a pixel coordinate in the visualization and its ridership as a
 * number of pixels radius.
 */
class PointWithRadius {
  
  private final String code;
  private final float x;
  private final float y;
  private final float radius;
  
  /**
   * Create a record of how to draw a glyph representing a station.
   *
   * @param newCode The two character code for the station.
   * @param newX The horizontal coordinate of the station in pixel-space.
   * @param newY The vertical coordinate of the station in pixel-space.
   * @param newRadius The radius of the ellipse to use to represent the station.
   */
  public PointWithRadius(String newCode, float newX, float newY,
    float newRadius) {
    code = newCode;
    x = newX;
    y = newY;
    radius = newRadius;
  }
  
  /**
   * Get the two character code of the station to be represented by a glyph.
   *
   * @return The two character code identifying the station.
   */
  public String getCode() {
    return code;
  }
  
  /**
   * Get the x coordinate of the glyph that will represent a station.
   *
   * @return Horizontal coordinate of the station in pixel-space.
   */
  public float getX() {
    return x;
  }
  
  /**
   * Get the y coordinate of the glyph that will represent a station.
   *
   * @return Vertical coordinate of the station in pixel-space.
   */
  public float getY() {
    return y;
  }
  
  /**
   * Get the radius of the glyph that will represent a station.
   *
   * @return The radius of this glyph's ellipse in pixels.
   */
  public float getRadius() {
    return radius;
  }
  
}


/**
 * Convert a station to a glyph representing that station.
 *
 * @param station The station to be visualized.
 * @return Information about how to draw a glyph (ellipse) representing that
 *    station.
 */
PointWithRadius makePointWithRadius(Station station) {
  GeoPoint point = new GeoPoint(station.getLongitude(), station.getLatitude());
  
  String code = station.getCode();
  float x = point.getX(mapView);
  float y = point.getY(mapView);
  float radius = getHaloRadius(station.getCount());
  
  return new PointWithRadius(code, x, y, radius);
}


/**
 * Place all of the stations and generate glyph information for them.
 *
 * @return Map from station two character code to information about how to draw
 *    a glyph representing that station.
 */
Map<String, PointWithRadius> getStationLocations() {
  return dataset.getStations()
    .stream()
    .map((x) -> makePointWithRadius(x))
    .collect(Collectors.toMap(
      (x) -> x.getCode(),
      (x) -> x
    ));
}


/**
 * Determine over which stations the user's cursor is hovering.
 *
 * @return Set of two character codes for the stations being higlighted
 *    (hovered over) by the user's cursor. May be an empty set if no stations
 *    highlighted.
 */
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


/**
 * Draw the transit layer with stations and journies visualized.
 *
 * @param higlightedCodes Set of codes corresponding to stations highlighted by
 *    the user.
 */
void drawStationsAndEdges(Set<String> highlightedCodes) {
  drawEdges(highlightedCodes);
  drawStations(highlightedCodes);
}


/**
 * Draw the stations piece of the stations and journies layer.
 *
 * @param higlightedCodes Set of codes corresponding to stations highlighted by
 *    the user.
 */
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
        .filter(
          (target) -> highlightedCodes.contains(target.getOther(stationCode))
        )
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


/**
 * Draw the journies piece of the stations and journies layer.
 *
 * @param higlightedCodes Set of codes corresponding to stations highlighted by
 *    the user.
 */
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
