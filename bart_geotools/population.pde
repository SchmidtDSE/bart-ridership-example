/**
 * Logic for drawing the population layer of the BART ridership visualization.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu) 
 */


/**
 * Draw the population layer.
 */
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
