-- Types of elements in the map
local EMPTY, EAST, SOUTH = 0, 1, 2
-- Map between value in input and its representation in the internal state
local inp_to_state = {["."] = EMPTY, [">"] = EAST, ["v"] = SOUTH}

-- Return the state array index for the given position
local function crd2idx(state, y, x)
    return y * state.cols + x + 1
end

-- Return a copy of the given array
local function copy_array(a)
    local res = {}
    for i = 1, #a do res[#res + 1] = a[i] end
    return res
end

-- Move to the east all the elements that can move (and should move) to the east.
-- Returns true if any elements moved, false otherwise
local function move_east(state)
    local new_data, crt_idx, moved = copy_array(state.data), 1, false
    for y = 0, state.lines - 1 do
        for x = 0, state.cols - 1 do
            if state.data[crt_idx] == EAST then -- check destination
                local next_x = (x + 1) % state.cols -- next column with wrapping
                local next_idx = crd2idx(state, y, next_x)
                if state.data[next_idx] == EMPTY then
                    new_data[crt_idx], new_data[next_idx] = EMPTY, EAST
                    moved = true
                end
            end
            crt_idx = crt_idx + 1
        end
    end
    state.data = new_data
    return moved
end

-- Move to the south all the elements that can move (and should move) to the south.
-- Returns true if any elements moved, false otherwise
local function move_south(state)
    local new_data, moved = copy_array(state.data), false
    for x = 0, state.cols - 1 do
        for y = 0, state.lines - 1 do
            local crt_idx = crd2idx(state, y, x)
            if state.data[crt_idx] == SOUTH then -- check destination
                local next_y = (y + 1) % state.lines -- next line with wrapping
                local next_idx = crd2idx(state, next_y, x)
                if state.data[next_idx] == EMPTY then
                    new_data[crt_idx], new_data[next_idx] = EMPTY, SOUTH
                    moved = true
                end
            end
        end
    end
    state.data = new_data
    return moved
end

-- Read input and return it in a table, together with the puzzle size (lines and columns)
local function read_input(fname)
    local data, lines, cols = {}, 0, 0
    for l in io.lines(fname) do
        l:gsub(".", function(c) data[#data + 1] = inp_to_state[c] end)
        cols, lines = #l, lines + 1
    end
    return {data=data, lines=lines, cols=cols}
end

local state, steps = read_input("input.txt"), 1
while true do
    -- Move to the east and then to the south, stop if no elements were moved
    local res1 = move_east(state)
    local res2 = move_south(state)
    if not res1 and not res2 then break end
    steps = steps + 1
end

print("Part 1:", steps)
print("Part 2: start the sleigh! :)")