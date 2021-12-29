open System.IO

// This keeps the data and current state of the algorithm
type Data =
    { rules: int[]                      // rule map
      pair_cnt: int64[]                 // count of element pairs at each step
      elements: int64[]                 // counts for each element
      mutable first_line: bool }        // "adding first line" flag

    // Maximum size of the rule array that covers all pairs from AA to ZZ
    static member max_size = 26 * 26;

    // Convert a single char to its array index
    static member single2idx n = int n - int 'A'

    // Convert a raw pair of numbers to their array index
    static member pair2idx n1 n2 = n1 * 26 + n2

    // Convert a numeric index back to a pair
    static member idx2pair i = (int i / 26, i % 26)

    // Increment the count for the given pair
    member this.add_pair n1 n2 =
        let idx = Data.pair2idx (Data.single2idx n1) (Data.single2idx n2)
        this.pair_cnt[idx] <- this.pair_cnt[idx] + 1L

    // Increment the count for the given element
    member this.add_element e =
        let idx = Data.single2idx e
        this.elements[idx] <- this.elements[idx] + 1L

    // Add a line from the input
    member this.add_line (l: string) =
        let len = l.Length
        if len > 0 then
            if this.first_line then // process all pairs in the input
                for i in 0 .. len - 2 do
                    this.add_pair l[i] l[i + 1] // increment count for this pair
                    this.add_element l[i] // increment element count only for the first element to avoid duplicates
                // We also have to increment the element count for the last element of the string
                this.add_element l[len - 1]
                this.first_line <- false
            else // mutation rule, add to the rule array
                let parts = l.Split " -> "
                let idx = Data.pair2idx (Data.single2idx parts[0].[0]) (Data.single2idx parts[0].[1])
                this.rules[idx] <- Data.single2idx parts[1].[0]

    // Run a single mutation step
    member this.step =
        // Since all the mutations happen in parallel, uses a copy of the current count array and keep the mutations
        // in a separate array that will be applied at the end of this step
        let temp = Array.copy this.pair_cnt
        let deltas = Array.create Data.max_size 0L
        for k in 0 .. temp.Length - 1 do
            if temp[k] > 0 then // found a pair, mutate it
                let (n1, n2) = Data.idx2pair k
                let m = this.rules[k] // mutation rule
                assert (m > 0)
                // Compute new keys
                let crt = this.pair_cnt[k]
                let newk1 = Data.pair2idx n1 m
                let newk2 = Data.pair2idx m n2
                // Increment corresponding pairs in the "delta" array
                deltas[newk1] <- deltas[newk1] + crt
                deltas[newk2] <- deltas[newk2] + crt
                // Increment element mount for the mutation
                this.elements[m] <- this.elements[m] + crt
                // And eliminate this pair from the pair_cnt for now since we mutated id
                this.pair_cnt[k] <- 0
        // Finally apply the computed deltas
        for i in 0 .. deltas.Length - 1 do
            this.pair_cnt[i] <- this.pair_cnt[i] + deltas[i]

    // Compute the solution at the current step
    member this.solution =
        // Sort all non-0 elements in the "elements" array
        let usable = this.elements |> Seq.filter (fun x -> x > 0) |> Seq.sort |> Seq.toArray
        // Return the difference between the highest count and the lowest count
        usable[usable.Length - 1] - usable[0]

// Run for the given number of steps and return the solution
let solution_for (data: Data) steps =
    for _ in 1 .. steps do data.step
    data.solution

// Read the input from the given file and return a Data corresponding to the input
let read_input fname =
    // Initialize the rules array with -1 (which means "pair not found") and the rest of the arrays with 0
    let res = { rules = Array.create Data.max_size -1
                pair_cnt = Array.create Data.max_size 0L
                elements = Array.create 26 0L
                first_line = true }
    File.ReadLines(fname) |> Seq.iter res.add_line // read and process each line in the input
    res

let data = read_input "input.txt"
printfn "Part 1: %d" (solution_for data 10)
printfn "Part 2: %d" (solution_for data 30) // run for the rest of the iterations