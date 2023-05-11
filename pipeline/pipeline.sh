echo "[1 / ] Prepare environment..."
pip install -r requirements.txt

echo "[2 / ] Downloading data..."
mkdir -p data
wget -P data http://64.111.127.166/ridership/Ridership_202304.xlsx
wget -P data https://www.bart.gov/sites/default/files/docs/BART_System_2020.kmz_.zip
wget -P data https://data.worldpop.org/GIS/Population/Global_2000_2020_1km/2020/USA/usa_ppp_2020_1km_Aggregated.tif

echo "[3 / ] Prepare data..."
cd data
xlsx2csv -n "Avg Weekday OD" ./Ridership_202304.xlsx ./ridership.csv
unzip BART_System_2020.kmz_.zip
unzip BART_System_2020.kmz
k2g ./doc.kml ./bart
cd ..

echo "[4 / ] Transform data..."
python geohash_population.py ./data/usa_ppp_2020_1km_Aggregated.tif ./data/population.csv

