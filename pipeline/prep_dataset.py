"""Script to build a dataset for a BART example for geotools for Procesing.

USAGE: python prep_rider_data.py [names] [geojson] [ridership] [population] [db]

(c) 2023 Regents of University of California / The Eric and Wendy Schmidt Center
for Data Science and the Environment at UC Berkeley.

This file is part of afscgap released under the BSD 3-Clause License. See
LICENSE.md.
"""

import csv
import json
import sqlite3
import sys
import typing

import geolib.geohash

# Constants for CLI
ARGS_STR = '[station names] [geojson] [ridership] [population] [output db]'
NUM_ARGS = 5
USAGE_STR = 'USAGE: python prep_rider_data.py ' + ARGS_STR

# Constants for name standardization
NAME_TRANSFORMS = {
    'Berryessa / North San José': 'Berryessa/North San Jose',
    'Civic Center': 'Civic Center/UN Plaza',
    'North Concord': 'North Concord/Martinez',
    'El Cerrito Del Norte': 'El Cerrito del Norte',
    'Berkeley': 'Downtown Berkeley',
    'Bayfair': 'Bay Fair',
    '16th Street Mission': '16th St/Mission',
    '24th Street Mission': '24th St/Mission',
    '12th Street / Oakland City Center': '12th St/Oakland City Center',
    'Montgomery Street': 'Montgomery St',
    'Pleasant Hill/Contra Costa Centre': 'Pleasant Hill',
    'Powell Street': 'Powell St',
    '19th Street Oakland': '19th St/Oakland',
    'Warm Springs/South Fremont': 'Warm Springs',
    'Coliseum/Airport Connector': 'Coliseum'
}

EXCLUDES = ['eBART Transfer']

# Constants for file reader automaton
STATE_WAITING = 0
STATE_READ_ORIGIN = 1
STATE_READ_ROW = 2
STATE_END = 3


class MetadataRecord:
    """Record of station's metadata including its physical location."""
    
    def __init__(self, name: str, latitude: float, longitude: float, code: str):
        """Create a new metadata record.

        Args:
            name: The full human readable name for the station like 19th Street
                Oakland.
            latitude: The latitude in degrees.
            longitude: The longitude in degrees.
            code: The internal code name that is used to refer to the station
                like 19. This should be two characters long.
        """
        self._name = name
        self._latitude = latitude
        self._longitude = longitude
        self._code = code
    
    def get_name(self) -> str:
        """Get the name of the station.

        Returns:
            The full human readable name for the station like 19th Street
            Oakland.
        """
        return self._name
    
    def get_latitude(self) -> float:
        """Get the geo-space vertical coordinate of the station.

        Returns:
            The station's vertical coordinate in degrees.
        """
        return self._latitude
    
    def get_longitude(self) -> float:
        """Get the geo-space horizontal coordinate of the station.

        Returns;
            The station's horizontal coordinate in degrees.
        """
        return self._longitude
    
    def get_code(self) -> str:
        """Get the short / code name for the station.

        Returns:
            The internal code name that is used to refer to the station like 19.
            This should be two characters long.
        """
        return self._code


class GraphWeight:
    """A single weighted edge in the station graph."""
    
    def __init__(self, source: str, destination: str, count: float):
        """Create a record of an edge.

        Args:
            source: Two character code for the first station.
            destination: Two character code for the second station.
            count: Weight or passenger count associated with the edge.
        """
        self._source = source
        self._destination = destination
        self._count = count
    
    def get_source(self) -> str:
        """Get the first station in this edge.

        Returns:
            Two character code for the first station.
        """
        return self._source
    
    def get_destination(self) -> str:
        """Get the second station in this edge.

        Returns:
            Two character code for the second station.
        """
        return self._destination
    
    def get_count(self) -> float:
        """Get the passenger traffic associated with this edge.

        Returns:
            Weight or passenger count associated with the edge.
        """
        return self._count


class GraphReader:
    """Reader for the graph of stations connected by passenger traffic.

    Automaton which helps prepare a graph made up of BART stations where each
    station is connected to another by weighted edges representing traffic
    between the two stations.

    Note that this produces undirected edges where the first station is the
    station of earlier alphanumeric order among the two stations in the edge.
    """
    
    def __init__(self):
        """Create a new empty graph reader."""
        self._state = STATE_WAITING
        self._origin_header = None
        self._weights = {}
        self._strategies = {
            STATE_WAITING: lambda line: self._on_wait(line),
            STATE_READ_ORIGIN: lambda line: self._on_read_origin(line),
            STATE_READ_ROW: lambda line: self._on_read_row(line),
            STATE_END: lambda line: self._on_end(line)
        }
    
    def step(self, line: str):
        """Read the next line of the input file.

        Args:
            line: The current line being parsed.
        """
        self._strategies[self._state](line)
    
    def finish(self) -> typing.List[GraphWeight]:
        """Indicate that the file is finished.

        Returns:
            Collection of edges making up the newly parsed graph as a list of
            GraphWeights.
        """
        self._state = STATE_END
        items = self._weights.items()
        items_obj = map(lambda x: self._make_output(x[0], x[1]), items)
        return list(items_obj)
    
    def _on_wait(self, line: str):
        """Action to take when waiting for the start of the file.

        Args:
            line: The current line being parsed.
        """
        self._state = STATE_READ_ORIGIN
    
    def _on_read_origin(self, line: str):
        """Parse the line in the file corresponding to the origin header.

        Args:
            line: The current line being parsed.
        """
        self._origin_header = list(line)
        self._origin_header[0] = 'exit'
        self._state = STATE_READ_ROW
    
    def _on_read_row(self, line: str):
        """Parse a row describing edge weights.

        Args:
            line: The current line being parsed.
        """
        row = dict(zip(self._origin_header, line))
        destination = row['exit']
        sources = filter(lambda x: x != 'exit', row.keys())
        sources_allowed = filter(lambda x: x != destination, sources)
        for source in sources_allowed:
            count = int(row[source].strip().replace(',', ''))
            self._add_count(source, destination, count)
    
    def _on_end(self, line: str):
        """Handle if a user asks to parse the next line on a completed file.

        Args:
            line: The current line being parsed.
        """
        raise RuntimeError('Asked to iterate on finalized reader.')
    
    def _add_count(self, source: str, destination: str, count: float):
        """Add new weight to an edge, creating that edge if it does not exist.

        Args:
            source: The first station in the edge.
            destination: The second station in the edge.
            count: The weight. Either will make an edge with this weight if the
                edge does not already exist or will add this weight to the edge
                if it already exists.
        """
        keys = sorted([source, destination])
        key = '\t'.join(keys)
        new_count = self._weights.get(key, 0) + count
        self._weights[key] = new_count
    
    def _make_output(self, key: str, count: float):
        """Make a new graph weight.

        Args:
            key: Key describing which stations are in the edge. Should be first,
                followed by \t followed by the second station.
            count: The weight for the new edge.

        Returns:
            Newly created edge.
        """
        key_pieces = key.split('\t')
        return GraphWeight(key_pieces[0], key_pieces[1], count)


class PopulationGridSpace:
    """Geohash with a population count."""
    
    def __init__(self, geohash: str, count: float):
        """Create a new geohash population record.

        Args:
            geohash: The geohash for which population was recorded.
            count: The population count.
        """
        self._geohash = geohash
        self._count = count
    
    def get_geohash(self) -> str:
        """Get the string geohash describing the location of this space.

        Returns:
            Geohash for this grid spot.
        """
        return self._geohash
    
    def get_count(self) -> float:
        """Get the estimated number of people at this space.

        Returns:
            Estimated population count in this geohash.
        """
        return self._count
    
    def get_latitude(self) -> float:
        """Get the vertical component of this space's location in geo-space.

        Returns:
            Center-point latitude in degrees for this grid space.
        """
        return float(geolib.geohash.decode(self._geohash)[0])
    
    def get_longitude(self) -> float:
        """Get the horizontal component of this space's location in geo-space.

        Returns:
            Center-point longitude in degrees for this grid space.
        """
        return float(geolib.geohash.decode(self._geohash)[1])


def load_station_names(filepath: str) -> typing.Dict[str, str]:
    """Load the station names mapping from 2 character code to full name.

    Args:
        filename: The location at which the CSV file can be found.
    """
    with open(filepath) as f:
        reader = csv.DictReader(f)
        code_tuples = map(
            lambda x: (x['Two-Letter Station Code'], x['Station Name']),
            reader
        )
        code_tuples_transformed = map(
            lambda x: (NAME_TRANSFORMS.get(x[1], x[1]), x[0]),
            code_tuples
        )
        return dict(code_tuples_transformed)


def simplify_record(target: typing.Dict,
    codes_reverse: typing.Dict[str, str]) -> MetadataRecord:
    """Simplify a geojson record of a station for the visualization dataset.

    Args:
        target: The dictionary from the geojson.
        codes_reverse: Mapping from station name to station two character code.

    Returns:
        Simplified record as a MetadataRecord.
    """
    name_raw = target['properties']['Name']
    
    name = NAME_TRANSFORMS.get(name_raw, name_raw)
    coordinates = target['geometry']['coordinates']
    latitude = coordinates[1]
    longitude = coordinates[0]
    code = codes_reverse[name]
    
    return MetadataRecord(name, latitude, longitude, code)


def load_stations(filepath: str,
    codes_reverse: typing.Dict[str, str]) -> typing.List[MetadataRecord]:
    """Load information about stations from a geojson file.

    Args:
        filepath: The path to the geojson file to process.
        codes_reverse: Mapping from station name to station two character code.

    Returns:
        List of newly created MetadataRecords.
    """
    with open(filepath) as f:
        stations_geojson = json.load(f)
        features = stations_geojson['features']
        features_allowed = filter(
            lambda x: x['properties']['Name'] not in EXCLUDES,
            features
        )
        return [simplify_record(x, codes_reverse) for x in features_allowed]


def load_ridership_data(filepath: str) -> typing.List[GraphWeight]:
    """Load ridership data as a graph of stations.

    Args:
        filepath: The path to the CSV file with ridership data.

    Returns:
        Loaded graph.
    """
    with open(filepath) as f:
        csv_reader = csv.reader(f)
        
        graph_reader = GraphReader()
        for row in csv_reader:
            graph_reader.step(row)
        
        return graph_reader.finish()


def load_population_data(filepath: str) -> typing.List[PopulationGridSpace]:
    """Load CSV file mapping geohash to estimated population.

    Args:
        filepath: Path to CSV file where the population data can be found.

    Returns:
        List of geohash grid spaces with populations.
    """
    with open('population.csv') as f:
        reader = csv.DictReader(f)
        return [
            PopulationGridSpace(x['geohash'], float(x['count'])) for x in reader
        ]


def export(db_path: str, simplified_meta: typing.Iterable[MetadataRecord],
    weights: typing.List[GraphWeight],
    population_grid: typing.List[PopulationGridSpace]):
    """Build the export database.

    Args:
        db_path: The path to the database where results should be exported.
        simplified_meta: Station metadata.
        weights: Ridership data as weigths between stations in a graph.
        population_grid: Information about population by geohash.
    """
    output_db = sqlite3.connect(db_path)
    cursor = output_db.cursor()

    # Build metadata
    cursor.execute(
        '''
        CREATE TABLE metadata (
            name TEXT,
            code TEXT,
            latitude FLOAT,
            longitude FLOAT
        )
        '''
    )

    metadata_tuples = map(
        lambda x: (x.get_name(), x.get_code(), x.get_latitude(), x.get_longitude()),
        simplified_meta
    )

    cursor.executemany(
        '''
        INSERT INTO metadata (name, code, latitude, longitude) VALUES (?, ?, ?, ?)
        ''',
        metadata_tuples
    )

    # Build weights
    cursor.execute(
        '''
        CREATE TABLE weights (
            source TEXT,
            destination TEXT,
            count FLOAT
        )
        '''
    )

    weights_tuples = map(
        lambda x: (x.get_source(), x.get_destination(), x.get_count()),
        weights
    )

    cursor.executemany(
        '''
        INSERT INTO weights (source, destination, count) VALUES (?, ?, ?)
        ''',
        weights_tuples
    )


    # Build population
    cursor.execute(
        '''
        CREATE TABLE populations (
            geohash TEXT,
            count FLOAT,
            latitude FLOAT,
            longitude FLOAT
        )
        '''
    )

    population_tuples = map(
        lambda x: (x.get_geohash(), x.get_count(), x.get_latitude(), x.get_longitude()),
        population_grid
    )

    cursor.executemany(
        '''
        INSERT INTO populations (geohash, count, latitude, longitude) VALUES (?, ?, ?, ?)
        ''',
        population_tuples
    )


    # Persist
    output_db.commit()
    output_db.close()


def main():
    """Run the script"""
    if len(sys.argv) != NUM_ARGS + 1:
        print(USAGE_STR)
        return

    station_names_path = sys.argv[1]
    geojson_path = sys.argv[2]
    ridership_path = sys.argv[3]
    population_path = sys.argv[4]
    output_path = sys.argv[5]

    codes_reverse = load_station_names(station_names_path)
    simplified_meta = load_stations(geojson_path, codes_reverse)
    weights = load_ridership_data(ridership_path)
    population_grid = load_population_data(population_path)

    export(output_path, simplified_meta, weights, population_grid)


if __name__ == '__main__':
    main()
