/**
 * Scales for drawing glyphs in the BART ridership visualization.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu) 
 */


/**
 * Get the radius to use when drawing an ellipse showing station ridership.
 *
 * @param count The average number of riders at the station.
 * @return The radius in pixels.
 */
float getHaloRadius(float count) {
  return sqrt(map(count, 0, maxStationCount, MIN_HALO_RADIUS, MAX_HALO_RADIUS));
}


/**
 * Get the width to use when drawing a journey between two stations.
 *
 * @param count The ridership / number of people taking the journey.
 * @return The strokeWeight in pixels.
 */
float getEdgeWidth(float count) {
  return map(count, 0, maxEdgeCount, MIN_EDGE_WIDTH, MAX_EDGE_WIDTH);
}


/**
 * Get the color with which a population grid space should be drawn.
 *
 * @param population The number of people in the grid space.
 * @return The color to use to draw that grid space.
 */
color getPopulationColor(float population) {
  int colorIndex = round(map(
    population,
    0,
    maxPopulation,
    0,
    POPULATION_COLORS.length
  ));
  if (colorIndex >= POPULATION_COLORS.length) {
    colorIndex = POPULATION_COLORS.length - 1;
  }
  return POPULATION_COLORS[colorIndex];
}
