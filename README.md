# BART Processing Geopoint Example
More "realistic" example for using the [Processing Geopoint](https://github.com/SchmidtDSE/processing-geopoint) library that interactively shows BART ridership by station and by journey (pair of stations where the system is entered and exited) with an optional population layer.

![Animated screenshot of a visualization showing journeys within BART using processing-geopoint.](https://gleap.org/static/img/bart_demo.gif)

<br>
<br>

## Purpose
Though the [Processing Geopoint](https://github.com/SchmidtDSE/processing-geopoint) documentation offers examples of use, they are generally quite small. This project provides a more realistic example of using these tools in a more complex sketch. Specifically, this mini-project explores ridership of the [Bay Area Rapid Transit system (BART)](https://bart.gov) in the San Francisco Bay Area.

<br>
<br>

## Installation
After [installing Processing](https://processing.org/download), simply clone this repository with `git clone git@github.com:SchmidtDSE/processing-geopoint.git`. Don't have `git` installed? You can also [download as a zip file from GitHub](https://github.com/SchmidtDSE/processing-geopoint/archive/refs/heads/main.zip).

<br>
<br>

## Usage
A pre-built dataset is included and can be run through the Processing IDE (PDE) or via the command line.

<br>

### PDE
Running via the PDE is simple:

 - Open the PDE.
 - Go to File > Open.
 - Open `bart_geotools.pde` within your copy of this repository.
 - Click run.

<br>

### Command line
If [processing-java]() is installed, you can do all of this from the command line at:

```
processing-java --sketch=bart_geotools --run
```

Just have `--sketch=bart_geotools` point to the `bart_geotools` directory within your copy of the repo.

<br>

### Build from scratch
The dataset is pre-built but the data pipeline can be run by using `pipeline/pipeline.sh`. Note that this is expected to be run on with the following dependencies already installed:

 - **Python 3**: Need an install with Python 3 and pip available. See the [Hitchiker's Guide for installation details](https://docs.python-guide.org/starting/installation/).
 - **wget**: This utility is typically pre-installed on Linux but can be added with `apt-get install wget` or equivalent. For Mac, consider the [wget brew formula](https://formulae.brew.sh/formula/wget). For Windows, consider a [third-party wget build](https://eternallybored.org/misc/wget/). Note that use of community builds is at your own risk.

If you are on Linux with aptitude, `build.sh` will install all dependencies (including Processing), run the data pipeline, and execute the sketch non-interactively.

<br>
<br>

## Method
The visualization deals with station ridership, journey ridership, and population estimations. Note that this describes the method currently employed on `main` but community members may choose to modify this behavior.

<br>

### Station ridership
The average weekday [BART ridership data](https://www.bart.gov/about/reports/ridership) are aggregated such that any passenger entering or exiting the BART system at that station is considered in its ridership. Note that this uses the `202304` release. This is then represented as the area of the circle used to represent a station in the visualization.

<br>

### Journey Ridership
A journey is the pairing of two stations such that all passengers entering at one station and exiting at another are considered in that journey's ridership. Put another way, passengers entering at station A and existing at station B are considered to be in the journey A - B.

By default, this is not directional (see `pipeline/prep_dataset.py:DIRECTED`). So, passengers entering at station B and exiting at station A are also considered to be part of the ridership for journey A - B. In other words, journey A - B is the same as journey B - A.

This visualization uses average weekday [BART ridership data](https://www.bart.gov/about/reports/ridership) from the `202304` release and represents ridership by `strokeWeight` (line width) for lines between the two stations involved in the journey.

<br>

### Population estimations
This visualization uses [WorldPop 2020 Unconstrained USA Population Counts](https://hub.worldpop.org/geodata/summary?id=29755) aggregated to a 5 letter [geohash](https://en.wikipedia.org/wiki/Geohash) by summing all pixels found within a geohash's bounds. These are then visualized using a sequential mono-chromatic color scale.

<br>
<br>

## Development standards
Processing code should use two space tabs and follow [standard Java conventions](https://google.github.io/styleguide/javaguide.html) where possible including JavaDoc on any public or global scope methods and classes. All Python code should follow the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html) where possible. At this stage, unit test targets are not enforced. Code should pass automated tests before merge.

<br>
<br>

## Contributing
Pull requests and bug reports welcome. We do not have a formalized template but please be kind. Open source is often a labor of love done outside work hours / pay. We may decline to fulfill a bug or merge a PR in which case we politely recommend a fork.

<br>
<br>

## License and open source
Released under the [BSD license](https://opensource.org/license/BSD-3-clause/). See [LICENSE.md](https://github.com/SchmidtDSE/afscgap/blob/main/LICENSE.md) for more details. Copyright Regents of University of California.

Visualization uses:

 - [ColorBrewer 2.0](https://colorbrewer2.org) under the [Apache 2.0 License](https://github.com/axismaps/colorbrewer/blob/master/LICENCE.txt).
 - [Silkscreen](https://kottke.org/plus/type/silkscreen/) under the [Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL).
 - [Processing](https://processing.org/) under the [LGPL](https://github.com/processing/processing4/blob/main/LICENSE.md)
 - [processing-geopoint](https://github.com/SchmidtDSE/processing-geopoint) under the [BSD License](https://github.com/SchmidtDSE/processing-geopoint/blob/main/LICENSE.md).

Data credits:

 - [BART geospatial KMLs](https://www.bart.gov/schedules/developers/geo) under the [BART DLA](https://www.bart.gov/schedules/developers/developer-license-agreement).
 - [BART ridership data](https://www.bart.gov/about/reports/ridership) under the [CC-BY-4.0 License](http://opendefinition.org/licenses/cc-by/).
 - [Natural Earth](https://www.naturalearthdata.com/downloads/50m-physical-vectors/) under the [public domain](https://www.naturalearthdata.com/about/terms-of-use/).
 - [WorldPop 2020 Unconstrained USA Population Counts](https://hub.worldpop.org/geodata/summary?id=29755) under the [CC-BY-4.0-International License](https://creativecommons.org/licenses/by/4.0/)

The data pipeline uses the following:

 - [geolib](https://github.com/joyanujoy/geolib) under the [MIT License](https://github.com/joyanujoy/geolib/blob/master/LICENSE).
 - [geotiff](https://github.com/KipCrossing/geotiff) under the [LGPL](https://github.com/KipCrossing/geotiff/blob/main/LICENSE).
 - [imagecodecs](https://pypi.org/project/imagecodecs/) under the [BSD License](https://github.com/cgohlke/imagecodecs/blob/master/LICENSE).
 - [kml2geojson](https://github.com/mrcagney/kml2geojson) under the [MIT License](https://github.com/mrcagney/kml2geojson/blob/master/LICENSE.txt).
 - [numpy](https://numpy.org/) under the [NumPy License](https://numpy.org/doc/stable/license.html#numpy-license).
 - [xlsx2csv](https://github.com/dilshod/xlsx2csv) under the [MIT License](https://github.com/dilshod/xlsx2csv/blob/master/LICENSE.txt).

Some bash scripts also use the following but are not linked and are, instead, simply called:

 - [X Window System and Xvfb](https://www.x.org/wiki/) under the [MIT License](https://x.org/releases/X11R7.7/doc/xorg-docs/License.html).
 - [OpenJDK](https://openjdk.org/) under the [GPL](https://github.com/openjdk/jdk/blob/master/LICENSE).

Sam Pottinger is the primary contact.
