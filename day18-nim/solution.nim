import strutils
import sequtils
import math
#import sugar

# The data is represented by a binary tree
type
    # A node in the tree can be either a leaf or a "tree node" with right and left children
    NodeKind = enum
        LEAF_NODE
        TREE_NODE
    # Recursive binary tree definition
    Node = ref object
        parent: Node # not strictly needed, but it makes it easier to replace nodes in explode/split operations
        case kind: NodeKind
            of LEAF_NODE: data: int
            of TREE_NODE: left, right: Node
    # A solver contains all the necessary data to solve the problem: the current tree and a list
    # of its leaf nodes (which simplifies the implementation of explode/split operations)
    Solver = object
        root: Node
        leaves: seq[Node]

#######################################################################################################################
# Various helpers

# Read the input data and return it as a sequence of strings
proc read_input(): seq[string] =
    let data = readFile("input.txt").strip()
    return data.splitLines()

# Build the tree representation of a pair (I can't get myself to call them "numbers").
# Also return a list of all the leaves in the tree
proc str_to_tree(s: string): (Node, seq[Node]) =
    type CharData = object
        c: char
        level: int
    var parse_data: seq[CharData] # parse data (pairs of (char, nesting_level))
    var leaves: seq[Node] # a list of all the leaves in the tree, in order
    # This is the function that builds the tree recursively
    proc build_tree(left: int, right: int, level: int, parent: Node = nil): Node =
        if left == right: # found a leaf node, so we need to also add it to the list of leaves
            let n = Node(kind: LEAF_NODE, data: ord(parse_data[left].c) - ord('0'), parent: parent)
            leaves.add(n)
            return n
        else: # we need to find the index of "level" between "left" and "right" and build subtrees recursively
            for i in left..right:
                if parse_data[i].level == level:
                    let n = Node(kind: TREE_NODE, parent: parent)
                    n.left = build_tree(left, i - 1, level + 1, n)
                    n.right = build_tree(i + 1, right, level + 1, n)
                    return n
            assert false
    var crt_level = 0
    # Read the string and associate a nesting level with each comma
    for c in s:
        if c == '[':
            crt_level += 1
        elif c == ']':
            crt_level -= 1
        else:
            parse_data.add(CharData(c: c, level: (if c == ',': crt_level else: 0)))
    let root = build_tree(0, parse_data.len - 1, 1)
    return (root, leaves)

#######################################################################################################################
# Methods for Node (trees)

# Prints the given tree using the pair representation
proc print(t: Node, level: int = 1) =
    case t.kind:
        of LEAF_NODE: stdout.write(t.data)
        of TREE_NODE:
            stdout.write("[")
            print(t.left, level + 1)
            stdout.write(",")
            print(t.right, level + 1)
            stdout.write("]")
    if level == 1:
        echo ""

# Returns true if the node is a "simple pair": a tree node with two leaves
proc is_simple_node(t: Node): bool =
    return t.kind == TREE_NODE and t.left.kind == LEAF_NODE and t.right.kind == LEAF_NODE

#######################################################################################################################
# Methods for Solver

# Return the magniture of a tree
proc get_magnitude(s: Solver): int =
    proc traverse(t: Node): int =
        return case t.kind:
            of LEAF_NODE: t.data
            of TREE_NODE: 3 * traverse(t.left) + 2 * traverse(t.right)
    return traverse(s.root)

# Try to explode the tree, returning true for success or false for error
proc explode(s: var Solver): bool =
    # Traverse the tree looking for a pair that can explore.
    # Return the node if found or "nil" otherwise
    proc traverse(t: Node, level: int): Node =
        assert level <= 5
        var res: Node = nil
        if t.kind == TREE_NODE: # leaves can never explode
            if level == 5: # can we explode this?
                res = (if t.is_simple_node(): t else: nil)
            else: # try to explode left/right
                res = traverse(t.left, level + 1)
                if res == nil:
                    res = traverse(t.right, level + 1)
        return res
    # Can we find an exploding node?
    let t = traverse(s.root, 1)
    if t == nil:
        return false
    # Found an exploding node, so:
    #   - update the next/previous numbers if they exist in s.leaves
    #   - replace it with a leaf node with value 0
    #   - remove the leaves of t from the solver's list of leaves and insert the new node
    # Find the indexes of the left and right child in the leaves array and update the leaves accordingly
    let left_idx = s.leaves.find(t.left)
    assert left_idx != -1
    if left_idx > 0:
        s.leaves[left_idx - 1].data += t.left.data
    let right_idx = s.leaves.find(t.right)
    assert right_idx != -1
    assert right_idx == left_idx + 1
    if right_idx < s.leaves.len - 1:
        s.leaves[right_idx + 1].data += t.right.data
    # Replace the node with a new leaf node with value 0
    let new_t = Node(kind: LEAF_NODE, data: 0, parent: t.parent)
    if t.parent != nil: # figure out which side to change (left or right)
        if t.parent.left == t:
            t.parent.left = new_t
        else:
            t.parent.right = new_t
    # Set left_idx to the new node in the leaves array and remove the right index
    s.leaves[left_idx] = new_t
    s.leaves.delete(right_idx .. right_idx)
    return true

# Try to split an element in the tree, returning true for success or false for error
proc split(s: var Solver): bool =
    # Look for the first leaf element with a value larger than 10
    for idx, t in s.leaves:
        if t.data >= 10: # found our node
            # We're going to modify the "leaves" array while iterating on it. Generally a bad idea, but not
            # in this case, since we're returning right after modifying.
            var new_t = Node(kind: TREE_NODE, parent: t.parent)
            new_t.left = Node(kind: LEAF_NODE, parent: new_t, data: floor(t.data.toFloat() / 2.0).toInt())
            new_t.right = Node(kind: LEAF_NODE, parent: new_t, data: ceil(t.data.toFloat() / 2.0).toInt())
            # Figure out which side to change (left or right)
            if t.parent != nil: # figure out which side to change (left or right)
                if t.parent.left == t:
                    t.parent.left = new_t
                else:
                    t.parent.right = new_t
            # Update the leaves array: replace element at index with new node, insert the new node at the next index
            s.leaves[idx] = new_t.left
            s.leaves.insert(new_t.right, idx + 1)
            return true
    return false

# Reduce the tree b applying explode/split operations until there are no more operations to apply
proc reduce(s: var Solver) =
    while true:
        if s.explode():
            continue
        if not s.split():
            break

# Add the given string to the solver
proc add(s: var Solver, data_array: varargs[string]) =
    for data in data_array:
        if s.root == nil: # this is the first input, create the tree directly
            (s.root, s.leaves) = str_to_tree(data)
        else:
            # Subsequent input: parse the data, create the new tree and reduce it
            let (new_root, new_leaves) = str_to_tree(data)
            s.root = Node(kind: TREE_NODE, left: s.root, right: new_root)
            s.root.left.parent = s.root
            s.root.right.parent = s.root
            s.leaves.add(new_leaves)
            s.reduce()

#######################################################################################################################
# Entry point

let input = read_input()

# Solve the first part: add all lines, compute final magnitude
var s = Solver()
for e in input:
    s.add(e)
echo "Part 1: ", s.get_magnitude()

# Solve the second part: consider all possible line pairs, find the maximum magnitude
var max_m = 0
for i, d1 in input:
    for j, d2 in input:
        if i != j:
            s = Solver()
            s.add(d1, d2)
            max_m = max(max_m, s.get_magnitude())
echo "Part 2: ", max_m
