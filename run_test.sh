echo "[1 / 5] System setup"
yes | sudo apt-get update
yes | sudo apt-get install xvfb libxrender1 libxtst6 libxi6 default-jdk

echo "[2 / 5] Loading Processing"
mkdir -p scratch
cd scratch
[[ ! -f processing-4.2-linux-x64.tgz ]] && wget https://github.com/processing/processing4/releases/download/processing-1292-4.2/processing-4.2-linux-x64.tgz
tar -xf processing-4.2-linux-x64.tgz
cd ..

echo "[3 / 5] Clear prior results"
[[ -f bart_geotools/bart.png ]] && rm bart_geotools/bart.png

echo "[4 / 5] Running sketch"
xvfb-run ./scratch/processing-4.2/processing-java --sketch=bart_geotools --run EM
sleep 1

echo "[5 / 5] Checking results"
[[ ! -f bart_geotools/bart.png ]] && exit 1
