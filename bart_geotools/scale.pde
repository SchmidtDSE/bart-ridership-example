float getHaloRadius(float count) {
  return sqrt(map(count, 0, maxStationCount, MIN_HALO_RADIUS, MAX_HALO_RADIUS));
}

float getEdgeWidth(float count) {
  return map(count, 0, maxEdgeCount, MIN_EDGE_WIDTH, MAX_EDGE_WIDTH);
}

color getPopulationColor(float population) {
  int colorIndex = round(map(population, 0, maxPopulation, 0, POPULATION_COLORS.length));
  if (colorIndex >= POPULATION_COLORS.length) {
    colorIndex = POPULATION_COLORS.length - 1;
  }
  return POPULATION_COLORS[colorIndex];
}
