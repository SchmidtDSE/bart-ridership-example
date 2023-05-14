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
