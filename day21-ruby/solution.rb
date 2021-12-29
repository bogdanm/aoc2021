# Indexes of various fields in the player representation in part1 (see below)
POS_IDX, SCORE_IDX = 0, 1

class Game
    # This maps each possible dice sum (3 to 9, for 3 rolls of the dice) to the number of times that the
    # sum appears in all dice combinations ([d1 + d2 + d3 for d1 = 1..3, d2 = 1..3, d3 = 1..3])
    # This is a bit better than generating all the above combinations (7 iterations instead of 27)
    @@dice_map = {3 => 1, 4 => 3, 5 => 6, 6 => 7, 7 => 6, 8 => 3, 9 => 1}

    # Initialize instace with initial player positions
    def initialize(pos1, pos2)
        @pos1 = pos1
        @pos2 = pos2
    end

    def part1
        # Each player is represented by a [position, score] pair
        players = [[@pos1, 0], [@pos2, 0]]
        dice, who, turns = 1, 0, 1
        while TRUE do
            # Roll dice 3 times, watching for overflow
            roll = 0
            for i in 1..3 do
                roll, dice = roll + dice, dice % 100 + 1
            end
            # Update current player's position and score
            players[who][POS_IDX] = (players[who][POS_IDX] + roll - 1) % 10 + 1
            players[who][SCORE_IDX] += players[who][POS_IDX]
            # Check if the current player won
            if players[who][SCORE_IDX]  >= 1000 then
                return players[1 - who][SCORE_IDX] * turns * 3
            end
            turns, who = turns + 1, 1 - who
        end
    end

    # The calls to solve2 below are cached in a hash (@c), which has a huge impact on the run time.
    def solve2(p1_pos, p1_score, p2_pos, p2_score, p1_turn=TRUE, roll=0)
        # Is the result for this bombination or aguments cached?
        # Combine the function's arguments in a string to make a key in the cache.
        key = "#{p1_pos},#{p1_score},#{p2_pos},#{p2_score},#{p1_turn},#{roll}"
        if @c.has_key?(key) then return @c[key] end
        # No cache, we actually have to compute this one.
        if roll > 0 then # skip initial update since we haven't generated any valid combination with the current data yet
            # Check if this is an winning state and return the corresponding win accordingly.
            if p1_turn then
                p1_pos = (p1_pos + roll - 1) % 10 + 1
                p1_score += p1_pos
                if p1_score >= 21 then return [1, 0] end
            else
                p2_pos = (p2_pos + roll - 1) % 10 + 1
                p2_score += p2_pos
                if p2_score >= 21 then return [0, 1] end
            end
            p1_turn = !p1_turn # change player
        end
        # Keep win counts in a (player1_wins, player2_wins) pair
        wins = [0, 0]
        # Iterate through all possible dice rolls
        @@dice_map.each do |r, cnt|
            # Get new winning scores for this updated state (new score/position/roll/turn)
            new_wins = solve2(p1_pos, p1_score, p2_pos, p2_score, p1_turn, r)
            # Multiply winnings with the roll's count
            wins[0] += new_wins[0] * cnt
            wins[1] += new_wins[1] * cnt
        end
        # Cache and return current result
        @c[key] = wins
        return wins
    end

    def part2
        @c = Hash.new # prepare solver cache
        return solve2(@pos1, 0, @pos2, 0).max
    end
end

# Read input and create game instance
input = File.readlines("input.txt").map {|l| l.split(": ")[1].to_i()}.compact
g = Game.new(input[0], input[1])
# Solve each part in turn
puts "Part 1: #{g.part1()}"
puts "Part 2: #{g.part2()}"