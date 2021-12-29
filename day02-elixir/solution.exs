# Read problem input
# Return a list of {:direction, amount} pairs
read_data2 = fn(fname) ->
  cvt = fn(parts) -> {String.to_atom(Enum.at(parts, 0)), String.to_integer(Enum.at(parts, 1))} end
  {:ok, contents} = File.read(fname)
  for x <- contents |> String.split("\n", trim: true), do: cvt.(String.split(x))
end

# Solve part 1
part1 = fn(l) ->
  r = Enum.reduce(l, [0, 0], fn(e, [h, d]) ->
    # Update height/depth according to the current entry
    case e do
      {:forward, n} -> [h + n, d]
      {:up, n} -> [h, d - n]
      {:down, n} -> [h, d + n]
    end
  end)
  Enum.at(r, 0) * Enum.at(r, 1) # return height * depth
end

# Solve part 2
part2 = fn(l) ->
  r = Enum.reduce(l, [0, 0, 0], fn(e, [h, d, a]) ->
    # Update height/depth/aim according to the current entry
    case e do
      {:forward, n} -> [h + n, d + a * n, a]
      {:up, n} -> [h, d, a - n]
      {:down, n} -> [h, d, a + n]
    end
  end)
  Enum.at(r, 0) * Enum.at(r, 1) # return height * depth
end

data = read_data2.("input.txt")
IO.puts "Part 1: #{part1.(data)}"
IO.puts "Part 2: #{part2.(data)}"
