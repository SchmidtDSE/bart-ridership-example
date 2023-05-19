"""Script to aggregate a population layer to geohashes

USAGE: python geohash_population.py

(c) 2023 Regents of University of California / The Eric and Wendy Schmidt Center
for Data Science and the Environment at UC Berkeley.

This file is part of afscgap released under the BSD 3-Clause License. See
LICENSE.md.
"""

import csv
import queue
import sys
import typing

import geolib.geohash  # type: ignore
import geotiff  # type: ignore
import numpy


ALLOWED_THREE_LETTERS = {
    '9qb',
    '9qc',
    '9q8',
    '9q9'
}

START_GEOHASH = '9q9p3'

NUM_ARGS = 2
USAGE_STR = 'USAGE: python geohash_population.py [tiff input] [csv output]'


class GeohashEnumerator(typing.Iterable[str]):
    """Iterator generator for geohashes that continually visits neighbors."""

    def __init__(self, start_geohash: str = START_GEOHASH):
        """Create a new iterator generator.
        
        Args:
            start_geohash: The initial geohash. If not provided defaults to
                START_GEOHASH
        """
        self._geohashes_seen = set()
        self._geohashes_waiting: queue.Queue[str] = queue.Queue()

        self._geohashes_seen.add(start_geohash)
        self._geohashes_waiting.put(start_geohash)

    def __iter__(self) -> typing.Iterator[str]:
        return self

    def __next__(self) -> str:
        if self._geohashes_waiting.empty():
            raise StopIteration()

        next_geohash = self._geohashes_waiting.get()

        neighbors = geolib.geohash.neighbours(next_geohash)
        allowed_neighbors = filter(
            lambda x: x[:3] in ALLOWED_THREE_LETTERS,
            neighbors
        )
        new_neighbors = filter(
            lambda x: x not in self._geohashes_seen,
            allowed_neighbors
        )

        for neighbor in new_neighbors:
            self._geohashes_seen.add(neighbor)
            self._geohashes_waiting.put(neighbor)

        return next_geohash


class PopulationGrid:
    """Record of a grid space in a geohashed gridded population layer."""

    def __init__(self, geohash: str, population: float):
        """Create a new record.
        
        Args:
            geohash: Geohash string that this grid space represents.
            population: Estimated population count in this geohash.
        """
        self._geohash = geohash
        self._population = population

    def get_geohash(self) -> str:
        """Get this grid space's geohash.
        
        Returns:
            Geohash string that this grid space represents.
        """
        return self._geohash

    def get_population(self) -> float:
        """Get the estimated population at this region.
        
        Returns:
            Estimated population count in this geohash.
        """
        return self._population


def read_box(target: geotiff.GeoTiff,
    bounds: typing.Iterable) -> typing.Optional[numpy.ndarray]:
    """Read a region from a geotiff.
    
    Args:
        target: The geotiff to read from.
        bounds: Coordinates to read like [[x1, y1], [x2, y2]]
    Returns:
        The pixels read or None if the region is out of bounds.
    """
    try:
        return numpy.clip(
            target.read_box(bounds),
            0,
            None
        )
    except geotiff.geotiff.BoundaryNotInTifError:
        return None


def get_sum(target: geotiff.GeoTiff,
    geohash: str) -> typing.Optional[PopulationGrid]:
    """Get the estimated total population in a region.
    
    Args:
        target: The geotiff to read from.
        geohash: The geohash for which a total should be calculated.
    
    Returns:
        Newly generated model representing the population in the geohash.
    """
    bounds_nest = geolib.geohash.bounds(geohash)
    bounds = [
        [bounds_nest[0][1], bounds_nest[0][0]],
        [bounds_nest[1][1], bounds_nest[1][0]]
    ]
    
    result = read_box(target, bounds)
    if result is None:
        return None
    
    result = float(numpy.sum(result))
    return PopulationGrid(geohash, result)


def get_sums(target: geotiff.GeoTiff) -> typing.Iterable[PopulationGrid]:
    """Generate a geohashed population grid.
    
    Args:
        target: The geotiff with population information.
    
    Returns:
        All of the geohashed population grid spaces found in the geotiff.
    """
    enumerator = GeohashEnumerator()
    raw_results = map(lambda geohash: get_sum(target, geohash), enumerator)
    return filter(lambda x: x is not None, raw_results)


def persist_results(results: typing.Iterable[PopulationGrid], location: str):
    """Save population grid spaces to a CSV file.
    
    Args:
        results: The population grid spaces to write to a CSV file.
        location: The file path to the CSV file that should be written.
    """
    result_dicts = map(lambda x: {
        'geohash': x.get_geohash(),
        'population': x.get_population()
    }, results)

    with open(location, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=['geohash', 'population'])
        writer.writeheader()
        writer.writerows(result_dicts)


def main():
    """Execute the script."""
    if len(sys.argv) != NUM_ARGS + 1:
        print(USAGE_STR)
        return

    input_tiff_path = sys.argv[1]
    output_path = sys.argv[2]

    tiff = geotiff.GeoTiff(input_tiff_path)
    sums = get_sums(tiff)
    persist_results(sums, output_path)


if __name__ == '__main__':
    main()
