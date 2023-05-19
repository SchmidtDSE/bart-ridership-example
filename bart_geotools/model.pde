/**
 * The model part of the the MVC structure for the visualization.
 *
 * The model part of the the MVC structure for the visualization that allows
 * querying of the visualization's sqlite dataset for geometries and information
 * about ridership.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of processing-geopoint released under the BSD 3-Clause License. See
 * LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu) 
 */

import java.sql.*;


/**
 * An edge representing journeys that start / end at two paired stations.
 *
 * An edge representing journeys that start / end at two paired stations which
 * is treated as directed but, in practice, may or may not be directed
 * depending on the underlying dataset preparation. See
 * pipeline/prep_dataset.py:DIRECTED.
 */
class Edge {
  
  private final String source;
  private final String destination;
  private final float count;

  /**
   * Create a new record of journeys between two stations.
   *
   * @param newSource The two character code of one station in the edge. Note
   *    that this can be used as the originating station if building a directed
   *    graph.
   * @param newDestination The two character code of the other station in the
   *    edge. Note that this can be used as the originating station if building
   *    a directed graph.
   */
  public Edge(String newSource, String newDestination, float newCount) {
    source = newSource;
    destination = newDestination;
    count = newCount;
  }
  
  /**
   * Get the first station in this edge.
   *
   * @return Two character station code of one of the stations in this edge. If
   *    being used in a directed graph, this is the station from which the
   *    journey commensed.
   */
  public String getSource() {
    return source;
  }
  
  /**
   * Get the first station in this edge.
   *
   * @return Two character station code of one of the stations in this edge. If
   *    being used in a directed graph, this is the station from which the
   *    journey commensed.
   */
  public String getDestination() {
    return destination;
  }
  
  /**
   * Get the number of passengers that took this edge's journey.
   *
   * @return Count of passengers that took part in the journey described by
   *    this edge in the dataset.
   */
  public float getCount() {
    return count;
  }
  
  /**
   * Determine if a station is involved in this edge.
   *
   * @param code The two character code of the station to check for.
   * @return True if one of the stations in this edge has a matching code and
   *    false otherwise.
   */
  public boolean contains(String code) {
    return source.equals(code) || destination.equals(code);
  }
  
  /**
   * Get the station code of the station that doesn't match the provided code.
   *
   * @param code The two character code for the station that should not be
   *    returned.
   * @return The two character code of the other station.
   * @throws RuntimeException Thrown if the provided code does not match
   *    either stations in this edge. 
   */
  public String getOther(String code) {
    if (source.equals(code)) {
      return destination;
    } else if (destination.equals(code)) {
      return source;
    } else {
      throw new RuntimeException("Code not present.");
    }
  }
  
}


/**
 * Model representing a station with a name, code, location, and traffic info.
 */
class Station {
  
  private final String name;
  private final String code;
  private final float latitude;
  private final float longitude;
  private final List<Edge> edges;
  private final float count;

  /**
   * Create a new station record.
   *
   * @param newName The full human-readable name of the station.
   * @param newCode The two character code identifying this station.
   * @param newLatitude The vertical geo-space coordinate of the station in
   *    degrees.
   * @param newLongitude The horizontal geo-space coordinate of the station in
   *    degrees.
   * @param newEdges The edges from this station to other stations.
   * @param newCount The number of passengers at the station. Note that this is
   *    an average so not a whole integer and includes those either entering
   *    BART at this station or leaving BART from this tation.
   */
  public Station(String newName, String newCode, float newLatitude,
    float newLongitude, List<Edge> newEdges, float newCount) {
    name = newName;
    code = newCode;
    latitude = newLatitude;
    longitude = newLongitude;
    edges = newEdges;
    count = newCount;
  }

  /**
   * Get the human-readable name of the station.
   *
   * @return Human-friendly name of the station.
   */
  public String getName() {
    return name;
  }
  
  /**
   * Get the two character code for this station.
   *
   * @return Two character unique code for this station.
   */
  public String getCode() {
    return code;
  }
  
  /**
   * Get the vertical location of this station in geo-space.
   *
   * @return The latitude of this station in degrees.
   */
  public float getLatitude() {
    return latitude;
  }
  
  /**
   * Get the horizontal location of this station in geo-space.
   *
   * @return The longitude of this station in degrees.
   */
  public float getLongitude() {
    return longitude;
  }
  
  /**
   * Get the edges for the journeys starting at or associated to this station.
   *
   * @return Edges that, in the directed case, originate from this station or,
   *    in the undirected case, are associated to this station.
   */
  public List<Edge> getEdges() {
    return edges;
  }
  
  /**
   * Get the average number of people going through this station.
   *
   * @return The number of passengers at the station. Note that this is an
   *    average so not a whole integer and includes those either entering BART
   *    at this station or leaving BART from this tation.
   */
  public float getCount() {
    return count;
  }
  
}


/**
 * A grid space in a population map layer.
 */
class Population {
  
  private final float count;
  private final float latitude;
  private final float longitude;

  /**
   * Create a new record of a grid space in a population layer.
   *
   * @param newCount The estimated number of people in this grid space. Note
   *    that this is an estimate so it is not necessarily a whole number.
   * @param newLatitude The latitude of the center of the grid space in degrees.
   * @param newLongitude The longitude of the center of the grid space in
   *    degrees.
   */
  public Population(float newCount, float newLatitude, float newLongitude) {
    count = newCount;
    latitude = newLatitude;
    longitude = newLongitude;
  }

  /**
   * Get the estimated number of people in this grid space.
   *
   * @return Estimated number of people in this grid space which may not be a
   *    whole number.
   */
  public float getCount() {
    return count;

  }
  
  /**
   * Get the vertical location of this grid space in geo-space.
   *
   * @return The latitude of the center of the grid space in degrees.
   */
  public float getLatitude() {
    return latitude;

  }
  
  /**
   * Get the horizontal location of this grid space in geo-space.
   *
   * @return The longitude of the center of the grid space in degrees.
   */
  public float getLongitude() {
    return longitude;

  }
  
}


/**
 * Object representing the entire dataset to be visualized.
 */
class Dataset {
  
  private final List<Station> stations;
  private final Map<String, Station> stationsByCode;
  private final List<Population> populations;
  private final GeoPolygon landPolygon;
  
  /**
   * Create a new record of a dataset.
   *
   * @param newStations The stations found in the dataset.
   * @param newPopulations Record of estimated populations in a geohash grid
   *    space.
   * @param newLandPolygon Polygon with land boundaries which will be displayed
   *    behind the visualization's main layers to offer a sense of reference.
   */
  public Dataset(List<Station> newStations, List<Population> newPopulations,
    GeoPolygon newLandPolygon) {
    stations = newStations;
    populations = newPopulations;
    landPolygon = newLandPolygon;
    stationsByCode = getStationsByCode(stations);
  }
  
  /**
   * Get the stations found in the dataset.
   *
   * @return List of stations found in the dataset with location, name, and
   *    ridership information.
   */
  public List<Station> getStations() {
    return stations;
  }
  
  /**
   * Get a estimated population layer as a geohash grid.
   *
   * @return List of models describing estimated populations in a geohash grid.
   */
  public List<Population> getPopulations() {
    return populations;
  }
  
  /**
   * Get a polygon representing bay area land.
   *
   * @return Polygon which can be used to draw the land reference layer.
   */
  public GeoPolygon getLandPolygon() {
    return landPolygon;
  }
  
  /**
   * Get the maximum reported station ridership.
   *
   * @returns The average number of passengers entering or exiting the station
   *    with the highest number of average passengers either entering or exiting
   *    BART at that station.
   */
  public float getMaxStationCount() {
    return stations.stream()
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  /**
   * Get the maximum reported estimated population grid space.
   *
   * @returns The estimated population of the geohash grid space with the
   *    highest estimated population in the dataset.
   */
  public float getMaxPopulation() {
    return populations.stream()
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  /**
   * Get the maximum reported journey ridership.
   *
   * @returns The average number of passengers taking a journey between two
   *    stations for the journey with the highest average ridership in the
   *    dataset.
   */
  public float getMaxEdgeCount() {
    return stations.stream()
      .flatMap((x) -> x.getEdges().stream())
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  /**
   * Get station information given that station's two character code.
   *
   * @param code The two character code for which station information should be
   *    returned.
   * @return Station information corresponding to the provided two character
   *    code.
   * @throws RuntimeException Thrown if a station with the given code was not
   *    found.
   */
  public Station getStationByCode(String code) {
    if (!stationsByCode.containsKey(code)) {
      throw new RuntimeException("Unknown station code: " + code);
    }
    return stationsByCode.get(code);
  }
  
  /**
   * Get a mapping from station code to station information.
   *
   * @param stations The stations to index into a Map.
   * @return Mapping from station code to station information.
   */
  private Map<String, Station> getStationsByCode(List<Station> stations) {
    return stations.stream().collect(Collectors.toMap(
      (x) -> x.getCode(),
      (x) -> x
    ));
  }
  
}


/**
 * Get the contents of a SQL file.
 *
 * @param loc The location of the SQL file.
 * @return The SQL script file contents as a multi-line string.
 */
String getSql(String loc) {
  String[] lines = loadStrings(loc);
  
  StringJoiner stringJoiner = new StringJoiner("\n");
  for (String line : lines) {
    stringJoiner.add(line);
  }
  
  return stringJoiner.toString();
}


/**
 * Load the visualization dataset.
 */
Dataset loadDataset() {
  String dbPath = dataPath("output.db");
  
  Connection connection = null;
  Dataset dataset = null;
  
  try {
    // Load dataset
    connection = DriverManager.getConnection("jdbc:sqlite:" + dbPath);
    Statement statement;
    
    // Load edges
    statement = connection.createStatement();
    statement.setQueryTimeout(30);
    ResultSet edgeResultSet = statement.executeQuery(getSql("edges.sql"));
    Map<String, List<Edge>> edges = new HashMap<>();
    while (edgeResultSet.next()) {
      String source = edgeResultSet.getString("source");
      String destination = edgeResultSet.getString("destination");
      float count = edgeResultSet.getFloat("count");
      
      Edge edge = new Edge(source, destination, count);
      
      if (!edges.containsKey(source)) {
        edges.put(source, new ArrayList<>());
      }
      edges.get(source).add(edge);
    }
    
    // Load stations
    statement = connection.createStatement();
    statement.setQueryTimeout(30);
    ResultSet stationResultSet = statement.executeQuery(getSql("stations.sql"));
    List<Station> stations = new ArrayList<>();
    while (stationResultSet.next()) {
      String name = stationResultSet.getString("name");
      String code = stationResultSet.getString("code");
      float latitude = stationResultSet.getFloat("latitude");
      float longitude = stationResultSet.getFloat("longitude");
      float count = stationResultSet.getFloat("count");
      
      List<Edge> stationEdges;
      if (edges.containsKey(code)) {
        stationEdges = edges.get(code);
      } else {
        stationEdges = new ArrayList<>();
      }
        
      Station newStation = new Station(
        name,
        code,
        latitude,
        longitude,
        stationEdges,
        count
      );
      
      stations.add(newStation);
    }
    
    // Load populations
    statement = connection.createStatement();
    statement.setQueryTimeout(30);
    ResultSet populationResultSet = statement.executeQuery(
      getSql("populations.sql")
    );
    List<Population> populations = new ArrayList<>();
    while(populationResultSet.next()) {
      float count = populationResultSet.getFloat("count");
      float latitude = populationResultSet.getFloat("latitude");
      float longitude = populationResultSet.getFloat("longitude");
      Population population = new Population(count, latitude, longitude);
      populations.add(population);
    }
    
    // Load land polygon
    statement = connection.createStatement();
    statement.setQueryTimeout(30);
    ResultSet landResultSet = statement.executeQuery(getSql("land.sql"));
    List<GeoPoint> landPoints = new ArrayList<GeoPoint>();
    while(landResultSet.next()) {
      float latitude = landResultSet.getFloat("latitude");
      float longitude = landResultSet.getFloat("longitude");
      GeoPoint newPoint = new GeoPoint(longitude, latitude);
      landPoints.add(newPoint);
    }
    GeoPolygon landPolygon = new GeoPolygon(landPoints);
    
    // Build dataset
    dataset = new Dataset(stations, populations, landPolygon);
  } catch (SQLException e) {
    throw new RuntimeException(e.getMessage());
  } finally {
    try {
      if (connection != null) {
        connection.close();
      }
    } catch (SQLException e) {
      throw new RuntimeException(e.getMessage());
    }
  }
  
  return dataset;
}
