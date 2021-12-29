import sys
import heapq

# Encoding of amphipods (affectionately called "dudes" below)
FREE, A, B, C, D = range(0, 5)

# Representation of a room, for convenience
class Room:
    # Mapping between the room number and its hallway index
    room_x = [2, 4, 6, 8]

    def __init__(self, depth, room, data):
        self.room = room
        self.x = self.room_x[room]
        self.data = data
        self.depth = depth

    # Dude accessors. The level is 0 for the top of the room, depth - 1 for the bottom
    def set_dude(self, level, dude):
        self.data[level + 1][self.x] = dude

    def get_dude(self, level):
        return self.data[level + 1][self.x]

    # Is this dude in its final room ?
    def dude_in_correct_room(self, level):
        return self.get_dude(level) == self.room + 1

    # Is this room complete ?
    def is_complete(self):
        return all([self.dude_in_correct_room(level) for level in range(self.depth)])

    # Return the number of dudes in their final positions in this room
    def get_num_final_dudes(self):
        s = 0
        for y in range(self.depth - 1, -1, -1):
            if not self.dude_in_correct_room(y):
                return s
            s += 1

    # Find the first dude that we can move from this room (if any)
    # Return its level if found, -1 otherwise
    def find_first_moveable_dude(self):
        for level in range(0, self.depth - self.get_num_final_dudes()):
            if self.get_dude(level) != FREE:
                return level
        return -1

class State:
    # Map between a dude and its representation
    dude2chr = {0: ".", A: "A", B: "B", C: "C", D: "D"}
    # Cost map
    costs = {A: 1, B: 10, C: 100, D: 1000}

    def __init__(self, depth, data=None):
        self.data = data
        # Data representation:
        #    - first line (0): hallway
        #    - next lines (1 to self.depth): rooms
        self.depth = depth
        if data is None:
            self.data = []
            for _ in range(1 + depth):
                self.data.append([FREE] * 11)
        self.hallway = self.data[0]
        self.rooms = [Room(depth, i, self.data) for i in range(4)]

    # Set a dude in a room (used when reading the input)
    def set_room(self, room, y, dude):
        self.rooms[room].set_dude(y, dude)

    # Hash function (neeed to store states in a dictionary)
    def __hash__(self):
        s = "".join([self.dude2chr[e] for e in self.hallway])
        for r in self.rooms:
            s = s + ";" + "".join([self.dude2chr[r.get_dude(y)] for y in range(self.depth)])
        return hash(s)

    def __eq__(self, other):
        return hash(self) == hash(other)

    # '<' is implemeted only to satify heapq's interface, otherwise all states are treated equally
    def __lt__(self, other):
        return False

    # Is this the final state (solution) ?
    def is_final(self):
        return all([r.is_complete() for r in self.rooms])

    # Count the number of dudes on the given room between the given columns
    def count_row(self, y, x1, x2):
        if x1 > x2:
            x1, x2 = x2, x1
        return sum([1 for x in range(x1, x2 + 1) if self.data[y][x] != FREE])

    # Count the number of dudes on the given column between the given rows
    def count_col(self, x, y1, y2):
        if y1 > y2:
            y1, y2 = y2, y1
        return sum([1 for y in range(y1, y2 + 1) if self.data[y][x] != FREE])

    # Return a deep copy of this state (needed when creating new states)
    def copy(self):
        return State(self.depth, [e[::] for e in self.data])

    def get_next_states(self):
        res = []
        # Create a new state for the given room, moving the dude in the room at the given level
        # to the hallway at index "new_x"
        def make_room_state(r, level, new_x):
            dude = r.get_dude(level)
            new_state = self.copy()
            new_state.hallway[new_x], new_state.data[level + 1][r.x] = dude, FREE
            res.append((new_state, self.costs[dude] * (abs(r.x - new_x) + level + 1)))
        # Try to move the dudes in the hallway
        for r in self.rooms:
            if self.hallway[r.x] != FREE or r.is_complete(): # can't move to the hallway / room is already complete
                continue
            # Find the first dude that we can move from this room (if any)
            level = r.find_first_moveable_dude()
            if level == -1:
                continue
            # Look left/right until we find either a wall or another dude and make a new state for each position
            # (but skip positions that are right on top of a room since would block the room)
            left_index, right_index = r.x - 1, r.x + 1
            while left_index >= 0 and self.hallway[left_index] == FREE:
                if left_index not in Room.room_x:
                    make_room_state(r, level, left_index)
                left_index -= 1
            while right_index < len(self.hallway) and self.hallway[right_index] == FREE:
                if right_index not in Room.room_x:
                    make_room_state(r, level, right_index)
                right_index += 1
        # Then try to move the dudes in the hallway to their rooms
        for (x, e) in enumerate(self.hallway):
            if e == FREE:
                continue
            # Found a dude in the hallway, find its target room and check of it can enter the room
            r = self.rooms[e - 1]
            assert not r.is_complete()
            target_y = self.depth - r.get_num_final_dudes() # move it to the topmost free position
            # Check if there is a path between the dude in the hallway and its destination in the room
            if self.count_row(0, x, r.x) + self.count_col(r.x, 0, target_y) != 1:
                continue
            # All good, create a new state with the dude moved to the room
            new_state = self.copy()
            new_state.hallway[x], new_state.data[target_y][r.x] = FREE, e
            res.append((new_state, self.costs[e] * (abs(r.x - x) + target_y)))
        return res

#########################################################################################################
# Entry point

# Create a state from the given string
def state_from_input(s):
    depth = len(s) - 3
    res = State(depth)
    for level, l in enumerate(s[2:]):
        for room, dude in enumerate(l.replace("#", "")):
            res.set_room(room, level, FREE if dude == "." else ord(dude) - ord('A') + 1)
    return res

def solve(s):
    # Keep the state space in a heap (priority queue) with the state of lowest cost at the top
    # Also keep a {state: min_cost} map for the visited states
    state_space, visited = [], {}
    heapq.heappush(state_space, (0, s)) # start from the initial state
    while state_space: # repeat until we still have states to test
        cost, s = heapq.heappop(state_space)
        if s.is_final(): # found the final state, return cost
            return cost
        # Generate all the next states
        for (next_state, c) in s.get_next_states():
            # If the state thas wasn't visited yet, or was visited with a higher cost, update
            # the state's cost and add it back to the state space
            if cost + c < visited.get(next_state, sys.maxsize):
                visited[next_state] = cost + c
                heapq.heappush(state_space, (cost + c, next_state))

# Read original input and solve the first part
with open("input.txt", "rt") as f:
    data = [l.strip() for l in f.readlines()]
print("Part 1: {}".format(solve(state_from_input(data))))
# Update original input and solve the second part
add_lines = ["#D#C#B#A#", "#D#B#A#C#"]
print("Part 2: {}".format(solve(state_from_input(data[:3] + add_lines + data[3:]))))