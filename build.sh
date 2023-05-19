echo "[1 / 7] System setup"
yes | sudo apt-get update
yes | sudo apt-get install xvfb libxrender1 libxtst6 libxi6 default-jdk

echo "[2 / 7] Loading Processing"
mkdir -p scratch
cd scratch
[[ ! -f processing-4.2-linux-x64.tgz ]] && wget https://github.com/processing/processing4/releases/download/processing-1292-4.2/processing-4.2-linux-x64.tgz
tar -xf processing-4.2-linux-x64.tgz
cd ..

echo "[3 / 7] Clear prior results"
[[ -f bart_geotools/bart.png ]] && rm bart_geotools/bart.png

echo "[4 / 7] Building dataset"
cd pipeline
bash pipeline.sh
cd ..

echo "[5 / 7] Distributing dataset..."
rm bart_geotools/data/output.db
cp pipeline/data/output.db ./bart_geotools/data

echo "[6 / 7] Running sketch"
xvfb-run ./scratch/processing-4.2/processing-java --sketch=bart_geotools --run EM
RETURN_CODE=$?

echo "[7 / 7] Checking results"
exit $RETURN_CODE
