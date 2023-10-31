#!/usr/bin/env bash
src="gunrock--gunrock"
bin="bin/pr"
out="$HOME/Logs/$src.log"
ulimit -s unlimited
printf "" > "$out"

# Download source code
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $src
  git clone https://github.com/wolfram77/$src
fi
cd $src

# Build and run
mkdir build && cd build
cmake ..
make -j32
bin/pr ~/Data/indochina-2004.mtx
stdbuf --output=L ./a.out ~/Data/indochina-2004.mtx  2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/uk-2002.mtx         2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/arabic-2005.mtx     2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/uk-2005.mtx         2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/webbase-2001.mtx    2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/it-2004.mtx         2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/sk-2005.mtx         2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/com-LiveJournal.mtx 2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/com-Orkut.mtx       2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/asia_osm.mtx        2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/europe_osm.mtx      2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/kmer_A2a.mtx        2>&1 | tee -a "$out"
stdbuf --output=L ./a.out ~/Data/kmer_V1r.mtx        2>&1 | tee -a "$out"
