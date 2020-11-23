#include <cstdlib>  // EXIT_SUCCESS

#include <gunrock/applications/bfs.hxx>

using namespace gunrock;
using namespace memory;

void test_bfs(int num_arguments, char** argument_array) {
  if (num_arguments != 2) {
    std::cerr << "usage: ./bin/<program-name> filename.mtx" << std::endl;
    exit(1);
  }

  // --
  // Define types

  using vertex_t = int;
  using edge_t = int;
  using weight_t = float;

  // --
  // IO

  std::string filename = argument_array[1];

  io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
  format::csr_t<memory::memory_space_t::device, vertex_t, edge_t, weight_t> csr;
  csr.from_coo(mm.load(filename));

  // --
  // Build graph + metadata

  auto [G, meta] = graph::build::from_csr_t<memory_space_t::device>(&csr);

  // --
  // Params and memory allocation

  vertex_t single_source = 0;

  vertex_t n_vertices = meta->get_number_of_vertices();
  thrust::device_vector<vertex_t> distances(n_vertices);
  thrust::device_vector<vertex_t> predecessors(n_vertices);

  // --
  // Run problem

  float elapsed =
      gunrock::bfs::run(G, meta, single_source, distances.data().get(),
                        predecessors.data().get());

  // --
  // Log

  std::cout << "Distances (output) = ";
  thrust::copy(distances.begin(), distances.end(),
               std::ostream_iterator<vertex_t>(std::cout, " "));
  std::cout << std::endl;
  std::cout << "BFS Elapsed Time: " << elapsed << " (ms)" << std::endl;
}

int main(int argc, char** argv) {
  test_bfs(argc, argv);
  return EXIT_SUCCESS;
}