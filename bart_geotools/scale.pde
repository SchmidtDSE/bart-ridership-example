float getHaloRadius(float count) {
  return sqrt(map(count, 0, maxStationCount, MIN_HALO_RADIUS, MAX_HALO_RADIUS));
}

float getEdgeWidth(float count) {
  return map(count, 0, maxEdgeCount, MIN_EDGE_WIDTH, MAX_EDGE_WIDTH);
}
