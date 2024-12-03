#include <gunrock/algorithms/pr.hxx>
#include <gunrock/util/performance.hxx>
#include <gunrock/io/parameters.hxx>
#include <cmath>
#include <vector>
#include <omp.h>

using namespace gunrock;
using namespace memory;




/**
 * Compute the L1-norm of the difference of two arrays in parallel.
 * @param x an array
 * @param y another array
 * @param N size of arrays
 * @param a initial value
 * @returns ||x-y||_1
 */
template <class TX, class TY, class TA=TX>
inline TA l1NormDeltaOmp(const TX *x, const TY *y, size_t N, TA a=TA()) {
  // ASSERT(x && y);
  #pragma omp parallel for schedule(auto) reduction(+:a)
  for (size_t i=0; i<N; ++i)
    a += TA(std::abs(x[i] - y[i]));
  return a;
}




void test_pr(int num_arguments, char** argument_array) {
  // --
  // Define types

  using vertex_t = int;
  using edge_t = int;
  using weight_t = float;

  using csr_t =
      format::csr_t<memory_space_t::device, vertex_t, edge_t, weight_t>;

  // --
  // IO

  gunrock::io::cli::parameters_t params(num_arguments, argument_array,
                                        "Page Rank");

  printf("Loading graph %s ...\n", params.filename.c_str());
  io::matrix_market_t<vertex_t, edge_t, weight_t> mm;
  auto [properties, coo] = mm.load(params.filename);
  printf("order: %d, size: %d, symmetric: %d\n", coo.number_of_rows, coo.number_of_nonzeros, properties.symmetric);

  csr_t csr;

  if (params.binary) {
    csr.read_binary(params.filename);
  } else {
    csr.from_coo(coo);
  }

  // --
  // Build graph

  auto G = graph::build<memory_space_t::device>(properties, csr);

  // --
  // Params and memory allocation

  srand(time(NULL));

  weight_t alpha = 0.85;
  weight_t tol = 1e-10;

  size_t n_vertices = G.get_number_of_vertices();
  size_t n_edges = G.get_number_of_edges();
  thrust::device_vector<weight_t> p(n_vertices);

  // Parse tags
  std::vector<std::string> tag_vect;
  gunrock::io::cli::parse_tag_string(params.tag_string, &tag_vect);

  // --
  // GPU Run

  std::vector<float> run_times;
  printf("Running PR ...\n");
  auto benchmark_metrics =
      std::vector<benchmark::host_benchmark_t>(params.num_runs);
  for (int i = 0; i < params.num_runs; i++) {
    benchmark::INIT_BENCH();

    run_times.push_back(gunrock::pr::run(G, alpha, tol, p.data().get()));

    benchmark::host_benchmark_t metrics = benchmark::EXTRACT();
    benchmark_metrics[i] = metrics;

    benchmark::DESTROY_BENCH();
  }

  // Placeholder since PR does not use sources
  std::vector<int> src_placeholder;

  // Export metrics
  if (params.export_metrics) {
    gunrock::util::stats::export_performance_stats(
        benchmark_metrics, n_edges, n_vertices, run_times, "pr",
        params.filename, "market", params.json_dir, params.json_file,
        src_placeholder, tag_vect, num_arguments, argument_array);
  }

  // Log
  print::head(p, 40, "GPU rank");

  // Copy p to host
  thrust::host_vector<weight_t> p_host = p;

  // Run PR with zero tolerance to find exact PageRanks
  printf("Running exact PR ...\n");
  thrust::device_vector<weight_t> p_exact(n_vertices);
  gunrock::pr::run(G, alpha, 0, p_exact.data().get());
  thrust::host_vector<weight_t> p_exact_host = p_exact;

  // Compute L1-norm of the difference between exact and approximate PageRanks
  printf("Computing error ...\n");
  weight_t l1_norm = l1NormDeltaOmp(p_host.data(), p_exact_host.data(), n_vertices);

  std::cout << "GPU Elapsed Time : " << run_times[params.num_runs - 1]
            << " (ms)" << std::endl;
  std::cout << "GPU Error : " << l1_norm << std::endl;
}

int main(int argc, char** argv) {
  test_pr(argc, argv);
}
