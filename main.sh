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
  gve add-self-loops -i "$1.mtx" -o "$1.self.mtx"
  stdbuf --output=L bin/pr -m "$1.self.mtx" 2>&1 | tee -a "$out"
  stdbuf --output=L printf "\n\n"                | tee -a "$out"
  rm -f "$1.self.mtx"
}

# Run on each graph
runAll() {
  runOne ~/Data/indochina-2004
  runOne ~/Data/uk-2002
  runOne ~/Data/arabic-2005
  runOne ~/Data/uk-2005
  runOne ~/Data/webbase-2001
  runOne ~/Data/it-2004
  runOne ~/Data/sk-2005
  runOne ~/Data/com-LiveJournal
  runOne ~/Data/com-Orkut
  runOne ~/Data/asia_osm
  runOne ~/Data/europe_osm
  runOne ~/Data/kmer_A2a
  runOne ~/Data/kmer_V1r
}

# Run 5 times
for i in {1..5}; do
  runAll
done

# Signal completion
curl -X POST "https://maker.ifttt.com/trigger/puzzlef/with/key/${IFTTT_KEY}?value1=$src$1"
