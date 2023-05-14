/**
 * Exmaple practical usage of the processing geotools using BART ridership data.
 *
 * Example "complete" practical sketch that demonstrates the use of processing
 * geotools in a more "real world" scenario. This program loads data from a
 * sqlite database, displays a map of the bay area with stations, allows
 * selections of those stations, and allows writing to a file.
 *
 * This can be run in interactive mode by simply executing the sketch without
 * additional parameters or by passing interactive as first argument. However,
 * it can also be run in demo mode for CI / CD by passing demo as first argument.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu)
 */

import java.util.*;
import java.util.stream.*;

Dataset dataset;
GeoTransformation mapView;
float maxStationCount;
float maxEdgeCount;


void setup() {
  size(900, 850);
  
  dataset = loadDataset();
  maxStationCount = dataset.getMaxStationCount();
  maxEdgeCount = dataset.getMaxEdgeCount();
  
  frameRate(15);
}


void draw() {
  background(#606060);
  
  mapView = new GeoTransformation(
    new GeoPoint(MAP_CENTER_LONGITUDE, MAP_CENTER_LATITUDE),
    new PixelOffset(MAP_CENTER_X, MAP_CENTER_Y),
    MAP_SCALE
  );
  
  Set<String> highlightedCodes = getHighlightedCodes();
  
  drawLand();
  drawEdges(highlightedCodes);
  drawStations(highlightedCodes);
}
