/**
 * The model part of the the MVC structure for the visualization.
 *
 * The model part of the the MVC structure for the visualization that allows
 * querying of the visualization's sqlite dataset for geometries and information
 * about ridership.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of afscgap released under the BSD 3-Clause License. See LICENSE.md.
 *
 * @license BSD
 * @author Sam Pottinger (dse.berkeley.edu) 
 */

import java.sql.*;


class Edge {
  
  private final String source;
  private final String destination;
  private final float count;

  public Edge(String newSource, String newDestination, float newCount) {
    source = newSource;
    destination = newDestination;
    count = newCount;
  }
  
  public String getSource() {
    return source;
  }
  
  public String getDestination() {
    return destination;
  }
  
  public float getCount() {
    return count;
  }
  
  public boolean contains(String code) {
    return source.equals(code) || destination.equals(code);
  }
  
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


class Station {
  
  private final String name;
  private final String code;
  private final float latitude;
  private final float longitude;
  private final List<Edge> edges;
  private final float count;

  public Station(String newName, String newCode, float newLatitude,
    float newLongitude, List<Edge> newEdges, float newCount) {
    name = newName;
    code = newCode;
    latitude = newLatitude;
    longitude = newLongitude;
    edges = newEdges;
    count = newCount;
  }

  public String getName() {
    return name;
  }
  
  public String getCode() {
    return code;
  }
  
  public float getLatitude() {
    return latitude;
  }
  
  public float getLongitude() {
    return longitude;
  }
  
  public List<Edge> getEdges() {
    return edges;
  }
  
  public float getCount() {
    return count;
  }
  
}


class Population {
  
  private final float count;
  private final float latitude;
  private final float longitude;

  public Population(float newCount, float newLatitude, float newLongitude) {
    count = newCount;
    latitude = newLatitude;
    longitude = newLongitude;
  }

  public float getCount() {
    return count;

  }
  
  public float getLatitude() {
    return latitude;

  }
  
  public float getLongitude() {
    return longitude;

  }
  
}


class Dataset {
  
  private final List<Station> stations;
  private final Map<String, Station> stationsByCode;
  private final List<Population> populations;
  private final GeoPolygon landPolygon;
  
  public Dataset(List<Station> newStations, List<Population> newPopulations,
    GeoPolygon newLandPolygon) {
    stations = newStations;
    populations = newPopulations;
    landPolygon = newLandPolygon;
    stationsByCode = getStationsByCode(stations);
  }
  
  public List<Station> getStations() {
    return stations;
  }
  
  public List<Population> getPopulations() {
    return populations;
  }
  
  public GeoPolygon getLandPolygon() {
    return landPolygon;
  }
  
  public float getMaxStationCount() {
    return stations.stream()
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  public float getMaxPopulation() {
    return populations.stream()
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  public float getMaxEdgeCount() {
    return stations.stream()
      .flatMap((x) -> x.getEdges().stream())
      .map((x) -> x.getCount())
      .max((a, b) -> a.compareTo(b))
      .get();
  }
  
  public Station getStationByCode(String code) {
    return stationsByCode.get(code);
  }
  
  private Map<String, Station> getStationsByCode(List<Station> stations) {
    return stations.stream().collect(Collectors.toMap(
      (x) -> x.getCode(),
      (x) -> x
    ));
  }
  
}


String getSql(String loc) {
  String[] lines = loadStrings(loc);
  
  StringJoiner stringJoiner = new StringJoiner("\n");
  for (String line : lines) {
    stringJoiner.add(line);
  }
  
  return stringJoiner.toString();
}


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
    ResultSet populationResultSet = statement.executeQuery(getSql("populations.sql"));
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
