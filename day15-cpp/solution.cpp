#include <queue>
#include <iostream>
#include <string>
#include <fstream>
#include <cstdint>
#include <limits>
#include <vector>
#include <cassert>

using namespace std;

// ********************************************************************************************************************
// Local functions and data

// Type of a graph node ID
typedef uint32_t node_id_t;

// This class keeps the implementation of a graph and its associated functions. It also keeps a multiplier that can be used
// to virtually increase the data in the initial input matrix (as requested by the second part of the puzzle).
class Graph {
public:
    Graph(): n(0), dim(0), inp_data() {}

    // Add a single line from the input to the data
    void add_line(const string& s) {
        if (n == 0) { // first time adding a line, allocate data and set the dimensions
            n = dim = s.length();
        }
        // Add each char to the input data
        for (auto &ch : s) {
            inp_data.push_back(ch - '0');
        }
    }

    // Set the multiplier for the input (used in part 2)
    void set_multiplier(uint32_t m) {
        dim = m * n; // also update current dimension
    }

    // Return the number of nodes (vertices) in the graph. There are n*n nodes plus a start node
    uint32_t get_num_nodes() const {
        return dim * dim + 1;
    }

    // Return the id of the last node
    node_id_t last_node_id() const {
        return dim * dim;
    }

    // Return the distance between nodes n1 and n2 or a negative value if there's not path between the nodes
    int32_t get_distance(node_id_t n1, node_id_t n2) const {
        int32_t res = -1;
        if (n1 == n2) { // d(n, n) = 0
            res = 0;
        } else if (n1 == 0) { // only return data for the initial node
            if (n2 == 1) {
                res = (int32_t)inp_data[0];
            }
        } else { // compute coordinates of both nodes and check if they are neighbors
            int32_t y_n1 = (n1 - 1) / dim, x_n1 = (n1 - 1) % dim;
            int32_t y_n2 = (n2 - 1) / dim, x_n2 = (n2 - 1) % dim;
            if (y_n1 == y_n2) { // check left/right
                if ((x_n2 == x_n1 + 1 && in_range(x_n1 + 1)) || (x_n2 == x_n1 - 1 && in_range(x_n1 - 1))) {
                    res = (int32_t)get_inp_data(y_n1, x_n2);
                }
            } else if (x_n1 == x_n2) { // check up/down
                if ((y_n2 == y_n1 + 1 && in_range(y_n1 + 1)) || (y_n2 == y_n1 - 1 && in_range(y_n1 - 1))) {
                    res = (int32_t)get_inp_data(y_n2, x_n1);
                }
            }
        }
        return res;
    }

    // Return all the neighbors of a given node
    vector<node_id_t> get_neighbors(node_id_t n) const {
        vector<node_id_t> res;

        if (n == 0) { // the only neighbor of the start node (0) is the first node in the actual matrix (1)
            res.push_back(1);
        } else {
            // Compute coordinates of the node
            uint32_t y_n = (n - 1) / dim, x_n = (n - 1) % dim;
            if (x_n > 0) { // append neighbor to the right
                res.push_back(node_id(y_n, x_n - 1));
            }
            if (x_n < dim - 1) { // append neighbor to the left
                res.push_back(node_id(y_n, x_n + 1));
            }
            if (y_n > 0) { // append neighbor to the top
                res.push_back(node_id(y_n - 1, x_n));
            }
            if (y_n < dim - 1) { // append neighbor to the bottom
                res.push_back(node_id(y_n + 1, x_n));
            }
        }
        return res;
    }

private:
    uint32_t n;                         // number of lines and columns in the graph
    uint32_t dim;                       // actual dimension that takes into account the multiplier
    vector<uint8_t> inp_data;           // input data (as read from the puzzle's input file)

    // Return the input data at the given coordinates, taking into account the multiplier
    uint8_t get_inp_data(uint32_t y, uint32_t x) const {
        // Compute actual coordinates into the matrix
        uint32_t mul_x = x / n, act_x = x % n;
        uint32_t mul_y = y / n, act_y = y % n;
        // Adjust value using mul_x/mul_y offsets computed relative to the multiplier
        uint8_t v = inp_data[act_y * n + act_x] + mul_x + mul_y;
        return v <= 9 ? v : v % 9;
    }

    // Return the ID of a graph node computed from the matrix coordinates
    node_id_t node_id(uint32_t y, uint32_t x) const {
        return y * dim + x + 1;
    }

    // Return true if the given coordinate is inside the matrix, false otherwise
    bool in_range(int32_t crt) const {
        return (crt >= 0) && (crt < dim);
    }
};

// Structure used for keeping elements in the priority queue (a distance and its associated node)
struct pq_data {
    int32_t     dist;
    node_id_t   node;

    pq_data(uint32_t d, node_id_t n): dist(d), node(n) {}
};

// Read data from the input file
static Graph read_data(const string& input_name) {
    fstream f;
    string l;
    Graph res;

    f.open(input_name, ios::in);
    while (getline(f, l)) {
        res.add_line(l);
    }
    return res;
}

// Djikstra implementation that uses a heap for O(n*log(n)) complexity instead of O(n ** 2)
// Turns out that n*log(n) is REALLY needed to solve this puzzle.
// Based on https://pythonalgos.com/2021/12/08/dijkstras-algorithm-in-5-steps-with-python/
static vector<int32_t> dijkstra(const Graph& g, node_id_t root) {
    const uint32_t n = g.get_num_nodes();
    const uint32_t infinity = INT32_MAX;

    // Setup the "distance" vector that is going to be the result of running this algorithm.
    // Set all distances to "infinity" at first, except for the distance to the root.
    vector<int32_t> dist(n, infinity);
    dist[root] = 0;
    // Setup the "visited" vector that tracks which nodes were already visited
    vector<bool> visited(n, false);
    // Also setup a priority queue. It keep pq_data elements (pairs of (distance, node)) and its
    // compare function sorts the distances.
    auto cmp = [](pq_data left, pq_data right) { return left.dist > right.dist;};
    priority_queue<pq_data, vector<pq_data>, decltype(cmp)> pq(cmp);

    pq.push(pq_data(0, root));
    while (!pq.empty()) {
        // Pop and remove top element
        pq_data top = pq.top();
        pq.pop();
        node_id_t u = top.node;
        // Skip the node if already visited, otherwise mark it as visited and process its neighbors
        if (visited[u]) {
            continue;
        }
        visited[top.node] = true;
        for (auto &v: g.get_neighbors(u)) {
            int32_t l = g.get_distance(u, v);
            // Update distance and priority queue if needed
            if (dist[u] + l < dist[v]) {
                dist[v] = dist[u] + l;
                pq.push(pq_data(dist[v], v));
            }
        }
    }
    return dist;
}

// ********************************************************************************************************************
// Public interface

int main() {
    // Read data from input
    Graph g = read_data("input.txt");

    // Solve first part with the initial input data
    auto p = dijkstra(g, 1);
    cout << "Part 1: " << p[g.last_node_id()] << endl;
    // Set the multiplier to 5 and solve the second part
    g.set_multiplier(5);
    p = dijkstra(g, 1);
    cout << "Part 2: " << p[g.last_node_id()] << endl;

    return 0;
}
