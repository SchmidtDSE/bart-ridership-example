void drawPopulation() {
  pushMatrix();
  pushStyle();
  
  noStroke();
  
  rectMode(RADIUS);
  
  for (Population population : dataset.getPopulations()) {
    fill(getPopulationColor(population.getCount()));
    
    GeoPoint point = new GeoPoint(population.getLongitude(), population.getLatitude());
    float x = point.getX(mapView);
    float y = point.getY(mapView); //<>//
    
    if (population.getCount() > 0) { //<>//
      rect(x, y, 19, 25);
    }
  }
  
  popStyle();
  popMatrix();
}
