#!/usr/bin/env bash
src="gunrock--gunrock"
out="$HOME/Logs/$src.log"
ulimit -s unlimited
printf "" > "$out"

# Download gunrock
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $src
  git clone https://github.com/wolfram77/$src
fi
cd $src

# Build gunrock
mkdir build && cd build
cmake -DCMAKE_CUDA_ARCHITECTURES=70 ..
make -j32

# Run gunrock PageRank on a graph
runGunrock() {
  stdbuf --output=L printf "Running PageRank on $1.mtx ...\n" | tee -a "$out"
  stdbuf --output=L bin/pr ~/Data/$1.mtx                 2>&1 | tee -a "$out"
  stdbuf --output=L printf "\n\n"                             | tee -a "$out"
}

# Run gunrock PageRank on all graphs
runGunrockAll() {
  runGunrock "indochina-2004"
  runGunrock "uk-2002"
  runGunrock "arabic-2005"
  runGunrock "uk-2005"
  runGunrock "webbase-2001"
  runGunrock "it-2004"
  runGunrock "sk-2005"
  runGunrock "com-LiveJournal"
  runGunrock "com-Orkut"
  runGunrock "asia_osm"
  runGunrock "europe_osm"
  runGunrock "kmer_A2a"
  runGunrock "kmer_V1r"
}

# Run gunrock PageRank 5 times
for i in {1..5}; do
  runGunrockAll
done

# Signal completion
curl -X POST "https://maker.ifttt.com/trigger/puzzlef/with/key/${IFTTT_KEY}?value1=$src$1"
