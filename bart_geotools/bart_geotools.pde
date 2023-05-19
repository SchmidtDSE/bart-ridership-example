/**
 * Exmaple practical usage of the processing geotools using BART ridership data.
 *
 * Example "complete" practical sketch that demonstrates the use of processing
 * geotools in a more "real world" scenario. This program loads data from a
 * sqlite database, displays a map of the bay area with stations, allows
 * selections of those stations, and allows writing to a file.
 *
 * If run with an argument, assumes it to be a two character code for the
 * station to be highlighted or "all" without quotes if all journeys should
 * be shown (no station highlighted).
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of processing-geopoint released under the BSD 3-Clause License. See
 * LICENSE.md.
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
  
  mapView = new GeoTransformation(
    new GeoPoint(MAP_CENTER_LONGITUDE, MAP_CENTER_LATITUDE),
    new PixelOffset(MAP_CENTER_X, MAP_CENTER_Y),
    MAP_SCALE
  );
  
  loadAssets();
  dataset = loadDataset();
  maxStationCount = dataset.getMaxStationCount();
  maxEdgeCount = dataset.getMaxEdgeCount();
  maxPopulation = dataset.getMaxPopulation();
  legendPanels = buildLegendPanels();
  populationPanel = new PopulationPanel();

  if (args != null) {
    assert args.length == 1;
    Set<String> highlighted = new HashSet<>();
    
    if (!args[0].equals("all")) {
      highlighted.add(args[0]);
    }

    redraw(highlighted);
    save("bart.png");
    exit();
  }
  
  frameRate(10);
}


/**
 * Preform a full redraw.
 *
 * @param highlightedCodes Set of stations highlighted by the user given those
 *    highlighted stations' two character codes.
 */
void redraw(Set<String> highlightedCodes) {
  background(#606060);
  
  if (showingPopulation) {
    drawPopulation();
  }
  
  drawLand();
  drawStationsAndEdges(highlightedCodes);
  drawUi(highlightedCodes);
}


/**
 * Preform a full redraw on main loop.
 */
void draw() {
  Set<String> highlightedCodes = getHighlightedCodes();
  redraw(highlightedCodes);
}


/**
 * Watch for the user enabling / disabling the population layer.
 */
void keyReleased() {
  if (key == 'p') {
    showingPopulation = !showingPopulation;
  }
}
