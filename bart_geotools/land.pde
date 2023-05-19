/**
 * Logic for drawing the land layer of the BART ridership visualization.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu) 
 */
 

/**
 * Draw the land layer (black outline).
 */
void drawLand() {
  pushMatrix();
  pushStyle();
  
  GeoPolygon landPolygon = dataset.getLandPolygon();
  noFill();
  strokeWeight(2);
  stroke(#333333);
  
  beginShape();
  landPolygon.draw((x, y) -> vertex(x, y), mapView);
  endShape();
  
  popStyle();
  popMatrix();
}
