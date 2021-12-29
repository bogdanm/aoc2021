use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::collections::HashMap;

// Represent the graph as a list of adjacent nodes for all nodes
type Graph = HashMap<String, Vec<String>>;
// Mapping between a node and its count while looking for a path
type NodeCnt = HashMap<String, u32>;
// Type of a predicate function for solve
type SolvePred = fn(&str, &NodeCnt) -> bool;

// Read the lines in the given file.
// The output is wrapped in a Result to allow matching on errors.
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path> {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

// Return true if a cave is a big cave, false otherwise
fn is_big(s: &str) -> bool {
    let upper_flag: Vec<bool> = s.chars().map(|c| c.is_ascii_uppercase()).collect();
    return !upper_flag.contains(&false);
}

// Predicate function for part 1
fn part1_pred(node: &str, path_cnt: &NodeCnt) -> bool {
    // OK to use this node if it is a big node or its count is 0
    is_big(node) || *path_cnt.get(node).or(Some(&0u32)).unwrap() == 0
}

// Predicate function for part 2
fn part2_pred(node: &str, path_cnt: &NodeCnt) -> bool {
    // The nodes that were eligible in part 1 are still eligible
    let mut can_add = part1_pred(node, path_cnt);
    // If can_add is false, it can still be possible to add the node if its count is 1
    // and no counts for small nodesw are 2
    if (!can_add) && node != "start" && *path_cnt.get(node).or(Some(&0u32)).unwrap() == 1 {
        can_add = true;
        for (_, v) in path_cnt.iter() {
            if *v == 2 { // found a node with count 2, bail out (only small nodes have entries in path_cnt)
                can_add = false;
                break;
            }
        }
    }
    can_add
}

// Solve the first part of the problem
fn solve(node: &str, data: &Graph, path_cnt: &mut NodeCnt, pred: SolvePred) -> u32 {
    if node == "end" { // found a new path to the end node
        1
    } else {
        let node_is_big = is_big(node);
        if !node_is_big { // increment path counter for a little node
            *path_cnt.entry(node.to_string()).or_insert(0) += 1;
        }
        let mut total = 0;
        // Call recursively for each neighbor that satisfies the "pred" function
        for n in data.get(node).unwrap().iter() {
            if pred(n, path_cnt) {
                total = total + solve(n, data, path_cnt, pred);
            }
        }
        if !node_is_big { // decrement the counter that was previously incremented for a little node
            *path_cnt.get_mut(node).unwrap() -= 1;
        }
        total
    }
}

fn main() {
    // Read lines in the input and build the matrix representation
    let mut data = Graph::new();
    for l in read_lines("input.txt").unwrap() {
        let p = l.unwrap();
        let parts = p.split("-").collect::<Vec<&str>>();
        // Update the adjacent list of nodes for each node in "parts"
        // Use the "entry" API to add a new neighbor or create a new neighbor array as needed
        data.entry(parts[0].to_string()).or_insert(vec!()).push(parts[1].to_string());
        data.entry(parts[1].to_string()).or_insert(vec!()).push(parts[0].to_string());
    }
    // Create an empty path count map and solve part 1
    let mut counts = NodeCnt::new();
    println!("Part 1: {}", solve("start", &data, &mut counts, part1_pred));
    // Create an empty path count map and solve part 2
    counts = NodeCnt::new();
    println!("Part 2: {}", solve("start", &data, &mut counts, part2_pred));
}
