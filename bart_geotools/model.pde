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
  
}


class Station {
  
  private final String name;
  private final String code;
  private final float latitude;
  private final float longitude;
  private final List<Edge> edges;

  public Station(String newName, String newCode, float newLatitude,
    float newLongitude, List<Edge> newEdges) {
    name = newName;
    code = newCode;
    latitude = newLatitude;
    longitude = newLongitude;
    edges = newEdges;
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
  private final List<Population> populations;
  
  public Dataset(List<Station> newStations, List<Population> newPopulations) {
    stations = newStations;
    populations = newPopulations;
  }
  
  public List<Station> getStations() {
    return stations;
  }
  
  public List<Population> getPopulations() {
    return populations;
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
      List<Edge> stationEdges = edges.get(name);
      Station newStation = new Station(name, code, latitude, longitude, stationEdges);
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
    
    // Build dataset
    dataset = new Dataset(stations, populations);
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
