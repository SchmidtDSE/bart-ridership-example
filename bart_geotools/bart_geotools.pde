/**
 * Exmaple practical usage of the processing geotools using BART ridership data.
 *
 * Example "complete" practical sketch that demonstrates the use of processing
 * geotools in a more "real world" scenario. This program loads data from a
 * sqlite database, displays a map of the bay area with stations, allows
 * selections of those stations, and allows writing to a file.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger, Magali de Bruyn (dse.berkeley.edu)
 */

import java.util.*;
import java.util.stream.*;

import org.dse.geopoint.*;

Dataset dataset;
GeoTransformation mapView;
float maxStationCount;
float maxEdgeCount;
float maxPopulation;
List<LegendPanel> legendPanels;
LegendPanel populationPanel;
boolean showingPopulation = false;


/**
 * Load the dataset and build the UI components.
 */
void setup() {
  size(900, 850);
  
  loadAssets();
  dataset = loadDataset();
  maxStationCount = dataset.getMaxStationCount();
  maxEdgeCount = dataset.getMaxEdgeCount();
  maxPopulation = dataset.getMaxPopulation();
  legendPanels = buildLegendPanels();
  populationPanel = new PopulationPanel();
  
  frameRate(10);
}


/**
 * Preform a full redraw.
 */
void draw() {
  background(#606060);
  
  mapView = new GeoTransformation(
    new GeoPoint(MAP_CENTER_LONGITUDE, MAP_CENTER_LATITUDE),
    new PixelOffset(MAP_CENTER_X, MAP_CENTER_Y),
    MAP_SCALE
  );
  
  Set<String> highlightedCodes = getHighlightedCodes();
  
  if (showingPopulation) {
    drawPopulation();
  }
  
  drawLand();
  drawStationsAndEdges(highlightedCodes);
  drawUi(highlightedCodes);
}


/**
 * Watch for the user enabling / disabling the population layer.
 */
void keyReleased() {
  if (key == 'p') {
    showingPopulation = !showingPopulation;
  }
}
