#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --exclusive
#SBATCH --job-name slurm
#SBATCH --output=slurm.out
# module load openmpi/4.1.5
# module load hpcx-2.7.0/hpcx-ompi
# source scl_source enable gcc-toolset-11
# source /opt/rh/gcc-toolset-13/enable
# module load cuda/12.3
src="gunrock--gunrock"
out="$HOME/Logs/$src$1.log"
ulimit -s unlimited
printf "" > "$out"

# Download source code
if [[ "$DOWNLOAD" != "0" ]]; then
  rm -rf $src
  git clone https://github.com/wolfram77/$src
  cd $src
fi

# Install gve.sh
npm i -g gve.sh

# Compile
mkdir build && cd build
cmake ..
make pr -j32
if [[ "$?" -ne "0" ]]; then
  echo "Compilation failed!"
  exit 1
fi

# Run on one graph
runOne() {
  gve add-self-loops -i "$1" -o "$1.self"
  stdbuf --output=L bin/pr "$1.self" 2>&1 | tee -a "$out"
}

# Run on each graph
runAll() {
  runOne ~/Data/indochina-2004.mtx
  runOne ~/Data/uk-2002.mtx
  runOne ~/Data/arabic-2005.mtx
  runOne ~/Data/uk-2005.mtx
  runOne ~/Data/webbase-2001.mtx
  runOne ~/Data/it-2004.mtx
  runOne ~/Data/sk-2005.mtx
  runOne ~/Data/com-LiveJournal.mtx
  runOne ~/Data/com-Orkut.mtx
  runOne ~/Data/asia_osm.mtx
  runOne ~/Data/europe_osm.mtx
  runOne ~/Data/kmer_A2a.mtx
  runOne ~/Data/kmer_V1r.mtx
}

# Run 5 times
for i in {1..5}; do
  runAll
done

# Signal completion
curl -X POST "https://maker.ifttt.com/trigger/puzzlef/with/key/${IFTTT_KEY}?value1=$src$1"
