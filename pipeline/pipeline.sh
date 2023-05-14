echo "[1 / 4] Prepare environment..."
pip install -r requirements.txt
wget -P data https://raw.githubusercontent.com/SchmidtDSE/processing-geopoint/main/polygon_to_csv.py

echo "[2 / 4] Downloading data..."
mkdir -p data
wget -P data http://64.111.127.166/ridership/Ridership_202304.xlsx
wget -P data https://www.bart.gov/sites/default/files/docs/BART_System_2020.kmz_.zip
wget -P data https://data.worldpop.org/GIS/Population/Global_2000_2020_1km/2020/USA/usa_ppp_2020_1km_Aggregated.tif

echo "[3 / 4] Prepare data..."
cd data
xlsx2csv -n "Avg Weekday OD" ./Ridership_202304.xlsx ./ridership.csv
unzip BART_System_2020.kmz_.zip
unzip BART_System_2020.kmz
k2g ./doc.kml ./bart
python polygon_to_csv.py ../preprepared/bayarea.geojson ./land.csv
cd ..

echo "[4 / 4] Transform data..."
python geohash_population.py ./data/usa_ppp_2020_1km_Aggregated.tif ./data/population.csv
python prep_dataset.py ./preprepared/station-names.csv ./preprepared/bayarea.geojson ./data/ridership.csv ./data/population.csv ./data/land.csv ./data/output.db
