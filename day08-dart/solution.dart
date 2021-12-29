import 'dart:io';

// Read and return input
List read_input(String fname) {
  // Read input and save it
  final lines = new File(fname).readAsLinesSync();
  var res = [];
  for (final l in lines) {
    // Line syntax: sequences | digits, so we need to split the line
    final parts = l.split(" | ");
    res.add([parts[0].split(" "), parts[1].split(" ")]);
  }
  return res;
}

// Return a set constructed from each char in the input string
Set<String> set_from_chars(String s) {
  var res = <String>{};
  for (final e in s.split("")) {
    res.add(e);
  }
  return res;
}

// Decode a digit from a string representation
String seg2dig(String s) {
  Map<String, String> m = const {
    "abcefg": '0',
    "cf": '1',
    "acdeg": '2',
    "acdfg": '3',
    "bcdf": '4',
    "abdfg": '5',
    "abdefg": '6',
    "acf": '7',
    "abcdefg": '8',
    "abcdfg": '9'
  };
  // Make sure that s is sorted alphabetically
  final List<String> t = s.split('');
  t.sort((a, b) => a.compareTo(b));
  return m[t.join()]!;
}

// Part 1: just count the total number of digits of size 2, 3, 4 or 7
int part1(List input) {
  var total = 0;
  final List<int> allowed = const [2, 3, 4, 7];
  for (final i in input) {
    final digs = i[1];
    for (final e in digs) {
      if (allowed.contains(e.length)) {
        total = total + 1;
      }
    }
  }
  return total;
}

// Return the solution for a single puzzle input.
int decode_entry(List entry) {
  final List<String> seqs = entry[0];
  // At this point, the result is a mapping between segments and a set of their possible values
  Map<String, Set<String>> res = {};
  for (final e in "abcdefg".split('')) {
    res[e] = <String>{};
  }
  // Sort the sequences by length to make things a bit easier
  // Since these are unique signal patterns of valid digits, the length will always be: 2 3 4 5 5 5 6 6 6 7
  seqs.sort((a, b) => a.length.compareTo(b.length));
  // Digit 1 has length 2 (so index 0 in seqs) and tells us the two possible values of the c and f segments.
  var temp = set_from_chars(seqs[0]);
  res['c']?.addAll(temp);
  res['f']?.addAll(temp);
  // Digit 7 (index 1) has 3 segments, two of which are common to digit 1, so the difference is the only possible value for segment 'a'
  res['a'] = set_from_chars(seqs[1]).difference(res['c']!);
  // Digit 4 (index 2) will give us the two possible values for segments b and d, since we already know the possible values of c and f
  temp = set_from_chars(seqs[2]).difference(res['c']!);
  res['b']?.addAll(temp);
  res['d']?.addAll(temp);
  // Now we can compute the two possible values for segments e and g by eliminating all the other values computed above
  temp = set_from_chars("abcdefg")
      .difference(res['a']!)
      .difference(res['b']!) // actually values for both b and d
      .difference(res['c']!); // actually values for both c and f
  res['e']?.addAll(temp);
  res['g']?.addAll(temp);
  // At this point we know:
  //   - The correct value for segment a.
  //   - Two possible and mutually exclusive values for segments c and f.
  //   - Two possible and mutually exclusive values for segments b and d.
  //   - Two possible and mutually exclusive values for segments e and g.
  // All we have to do now is:
  //   - Compute the intersection of all 6 segments digits which are 0, 6, 9 (indexes 6, 7, 8 in seqs). The intersection is always the possible
  //     values for segments a, b, f, and g.
  //   - Remove the known value for segment a from the set above. We are left with the values for segment b, f and g.
  //   - Since the values of b, f and g are already in disjoint sets of two possible values ([b, d], [f, c] and [g, e]), simply locate their
  //     values in the already known list of possible values.
  // Turns out that's all we need. The other entries (for digits 2, 3, 5) are irrelevant.
  // There are probably variations of this algorithm that use fewer digits or other digit combinations, but I doubt they could be more efficient
  // than this one (in terms of algorithmic complexity).
  temp = set_from_chars(seqs[6])
      .intersection(set_from_chars(seqs[7]))
      .intersection(set_from_chars(seqs[8]))
      .difference(res['a']!);
  final Map<String, String> pairs = const {"b": "d", "g": "e", "f": "c"};
  for (final s in temp) {
    for (final p in ['b', 'g', 'f']) {
      if (res[p]?.lookup(s) != null) {
        // found segment, set its value and its counterpart's (pairs[p]) value.
        res[p] = {s};
        res[pairs[p]!]?.remove(s);
      }
    }
  }
  // Compute final decode map by reverting the keys and values in "res"
  Map<String, String> decode = {};
  for (final e in res.keys) {
    decode[res[e]!.first] = e;
  }
  // And compute the correponding digit values
  final List<String> digs = entry[1];
  String n = ''; // the final result (as a string for now)
  for (final d in digs) {
    // Map the segments to their correct values in "decode"
    String f = '';
    for (final e in d.split('')) {
      f = f + decode[e]!;
    }
    // Get the number corresponding to the segments in the decoded 7-segment display and append it to the current number
    n = n + seg2dig(f);
  }
  return int.parse(n);
}

void main() {
  final input = read_input('input.txt');
  // The easy part
  print('Part 1: ${part1(input)}');
  // The more involved part: get the digits for all the entries and sum them.
  int total = 0;
  for (final e in input) {
    total = total + decode_entry(e);
  }
  print('Part 1: ${total}');
}
