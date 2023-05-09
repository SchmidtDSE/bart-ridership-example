import csv
import sys
import typing

import geolib  # type: ignore
import geotiff  # type: ignore
import numpy


ALLOWED_THREE_LETTERS = {
    '9qb',
    '9qc',
    '9q8',
    '9q9'
}

START_GEOHASH = '9q9p'

NUM_ARGS = 2
USAGE_STR = 'USAGE: python geohash_population.py [tiff input] [csv output]'


class GeohashEnumerator(typing.Iterable[str]):

    def __init__(self, start_geohash: str = START_GEOHASH):
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

    def __init__(self, geohash: str, population: float):
        self._geohash = geohash
        self._population = population

    def get_geohash(self) -> str:
        return self._geohash

    def get_population(self) -> float:
        return self._population


def read_box(target: geotiff.GeoTiff,
    bounds: typing.Iterable) -> typing.Optional[numpy.ndarray]:
    try:
        return numpy.clip(
            target.read_box(bounds),
            0,
            None
        )
    except geotiff.geotiff.BoundaryNotInTifError:
        return None


def get_sum(target: geotiff.GeoTiff, geohash: str) -> typing.Optional[float]:
    bounds_nest = geolib.geohash.bounds(geohash)
    bounds = [
        [bounds_nest[0][1], bounds_nest[0][0]],
        [bounds_nest[1][1], bounds_nest[1][0]]
    ]
    
    result = read_box(target, bounds)
    if result is None:
        return None
    
    return float(numpy.sum(result))


def get_sums(target: geotiff.GeoTiff) -> typing.Iterable[PopulationGrid]:
    enumerator = GeohashEnumerator()
    return map(lambda geohash: get_sum(target, geohash), enumerator)


def persist_results(results: typing.Iterable[PopulationGrid], location: str):
    result_dicts = map(lambda x: {
        'geohash': x.get_geohash(),
        'population': x.get_population()
    }, results)

    with open(location, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=['geohash', 'population'])
        writer.writeheader()
        writer.writerows(result_dicts)


def main():
    if len(sys.argv) != NUM_ARGS + 1:
        print(USAGE_STR)
        return

    input_tiff_path = sys.argv[1]
    output_path = sys.argv[2]

    geotiff = geotiff.GeoTiff(input_tiff_path)
    sums = get_sums(geotiff)
    persist_results(sums, output_path)
