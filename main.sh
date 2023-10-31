#!/usr/bin/env bash
src="gunrock--gunrock"
out="$HOME/Logs/$src.log"
csr="bin/csr_binary"
bin="bin/pr"
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

perform() {
cmd=$1
ext=$2
stdbuf --output=L $cmd ~/Data/indochina-2004$ext  2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/uk-2002$ext         2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/arabic-2005$ext     2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/uk-2005$ext         2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/webbase-2001$ext    2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/it-2004$ext         2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/sk-2005$ext         2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/com-LiveJournal$ext 2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/com-Orkut$ext       2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/asia_osm$ext        2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/europe_osm$ext      2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/kmer_A2a$ext        2>&1 | tee -a "$out"
stdbuf --output=L $cmd ~/Data/kmer_V1r$ext        2>&1 | tee -a "$out"
}

# Convert MTX to CSR
perform $csr ".mtx"

# Run PageRank on MTX
perform $bin ".mtx"

# Run PageRank on CSR
perform $bin ".mtx.csr"
