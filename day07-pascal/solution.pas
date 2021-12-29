program solution;
uses strutils, types, sysutils;

type TInputData = Array of LongInt;

var
    input: TInputData; // input data as an array of numbers

// Read input data and return it as an array of numbers
function read_input(name: string): TInputData;
var
    data_file: text;
    input: AnsiString;
    input_parts: TStringDynArray;
    l, i: SizeInt;
begin
    // Read input file
    assign(data_file, name);
    reset(data_file);
    readln(data_file, input);
    close(data_file);
    // Split input into parts
    input_parts := SplitString(input, ',');
    l := Length(input_parts);
    SetLength(Result, l);
    // And convert each part into a number
    for i := 0 to l - 1 do
    begin
        Result[i] := StrToInt(input_parts[i]);
    end;
end;

// Solve either the first part of the second part, according to "first_part"
function solve(first_part: Boolean): LongInt;
var
    min_cost, crt_cost, temp: LongInt;
    min_set: Boolean = false;
    i, j: Integer;
    l: SizeInt;
begin
    l := Length(input);
    min_cost := 0;
    // Try each position in turn. There are probably better ways to do this, but this is good enough
    // for the size of the input.
    for i := 0 to l - 1 do
    begin
        crt_cost := 0;
        for j := 0 to l - 1 do
        begin
            temp := abs(input[j] - input[i]);
            // The only thing that's different between part 1 and part is the cost function:
            //   - part 1: direct distance (temp above)
            //   - part 2: the sum of the first "temp" natural numbers.
            if first_part then
                crt_cost := crt_cost + temp
            else
                crt_cost := crt_cost + Trunc((temp * (temp + 1)) / 2);
        end;
        // Update minimum cost if needed
        if (crt_cost < min_cost) or (not min_set) then
        begin
            min_set := true;
            min_cost := crt_cost;
        end;
    end;
    Result := min_cost
end;

begin
    input := read_input('input.txt');
    writeln('Part 1: ', solve(true));
    writeln('Part 2: ', solve(false));
end.