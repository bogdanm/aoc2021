import java.util.*;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class Solution {
    // ****************************************************************************************************************
    // Internal data and constructor

    private ArrayList<Instruction> instructions;        // list of ALU instructions
    private ArrayList<Result> all_results;              // all the values after running the interpreter

    // Map between an instruction string and its Operation value
    private static HashMap<String, Operation> str_to_op = new HashMap<>();
    static {
        str_to_op.put("inp", Operation.INP);
        str_to_op.put("add", Operation.ADD);
        str_to_op.put("sub", Operation.SUB);
        str_to_op.put("mul", Operation.MUL);
        str_to_op.put("div", Operation.DIV);
        str_to_op.put("mod", Operation.MOD);
        str_to_op.put("eql", Operation.EQL);
        str_to_op.put("neq", Operation.NEQ);
    }

    public Solution() {
        instructions = new ArrayList<>();
        all_results = new ArrayList<>();
    }

    // ****************************************************************************************************************
    // A (conditions, result) pair represents the final result of the ALU program's "z" variable evaluated in the
    // context of the conditions

    class Result {
        public ArrayList<Expression> conditions;
        public Expression z;

        public Result(ArrayList<Expression> conditions, Expression z) {
            this.conditions = conditions;
            this.z = z;
        }
    }

    // ****************************************************************************************************************
    // A (min, max) pair for storing the limits of an expression and for computing limit intersections.

    class Limits {
        public long min, max;

        public Limits(long min, long max) {
            this.min = min;
            this.max = max;
        }

        public boolean intersects(Limits other) {
            return this.min < other.max || this.max < other.min;
        }
    }

    // ****************************************************************************************************************
    // A (digit, value) pair as returned by check_digit_condition in Expression

    class DigitValue {
        public int dig_no, val;

        public DigitValue(int dig_no, int val) {
            this.dig_no = dig_no;
            this.val = val;
        }
    }

    // ****************************************************************************************************************
    // The kind of operations performed by the ALU

    enum Operation {
        INP {
            public String toString() { // this is never used in an Expression (below)
                return "inp";
            }
        },    // read data
        ADD {
            public String toString() {
                return "+";
            }
        },
        SUB {
            public String toString() {
                return "-";
            }
        },
        MUL {
            public String toString() {
                return "*";
            }
        },
        DIV {
            public String toString() {
                return "/";
            }
        },
        MOD {
            public String toString() {
                return "%";
            }
        },
        EQL {
            public String toString() {
                return "==";
            }
        },
        NEQ {
            public String toString() {
                return "!=";
            }
        }
    }

    // ****************************************************************************************************************
    // Possible types for an expression (see below)

    enum ExpressionKind {
            NUMBER, SYMBOL, TREE
    }

    // ****************************************************************************************************************
    // An expression holds the value of a variable in 3 possible ways:
    //   - as a number
    //   - as a symbol (w, x, y, z, d0, d1...)
    //   - as an tree (binary tree for computing the valeus of expressions) with "op" holding an Operation and "left" and "right"
    //     holding the operands

    class Expression {
        public ExpressionKind kind;     // the kind of expression
        public String v;                // the value of the expression as a string
        public long num_v;              // the integer value of this expression, if applicable
        public Operation op;            // operation for a TREE kind
        public Expression left, right;  // operand for a TREE kind

        // Constructor for a simple value (number or symbol)
        public Expression(String v) {
            this.v = v;
            try {
                num_v = Long.parseLong(v);
                kind = ExpressionKind.NUMBER;
            } catch (Exception e) {
                num_v = 0;
                kind = ExpressionKind.SYMBOL;
            }
            op = Operation.INP;
            left = null;
            right = null;
        }

        // Constructor for an integer value
        public Expression(long v) {
            num_v = v;
            this.v = Long.toString(v);
            kind = ExpressionKind.NUMBER;
            op = Operation.INP;
            left = null;
            right = null;
        }

        // Constructor for a TREE value
        public Expression(Operation op, Expression left, Expression right) {
            kind = ExpressionKind.TREE;
            this.op = op;
            this.left = left;
            this.right = right;
            v = "";
            num_v = 0;
        }

        // Recursive to_string method for TREE expressions
        private String to_string(int level) {
            if (kind == ExpressionKind.NUMBER || kind == ExpressionKind.SYMBOL) { // return the value
                return v;
            } else { // build the value by evaluating left/right subtrees
                assert op != Operation.INP;
                String prefix = level == 0 ? "" : "(";
                String suffix = level == 0 ? "" : ")";
                return prefix + left.to_string(level + 1) + " " + op.toString() + " " + right.to_string(level + 1) + suffix;
            }
        }

        // Return the string representation of this expression
        public String toString() {
            return to_string(0);
        }

        // Return the result of the current instance using the given left/right numbers
        private long num_op(long left, long right) {
            assert kind == ExpressionKind.TREE;
            long res = 0;
            switch (op) {
                case ADD:
                    res = left + right;
                    break;
                case SUB:
                    res = left - right;
                    break;
                case MUL:
                    res = left * right;
                    break;
                case DIV:
                    res = left / right;
                    break;
                case MOD:
                    res = left % right;
                    break;
                default:
                    assert false;
            }
            return res;
        }

        // Evaluate the value represented in this Expression by interpreting the operator in the context
        // of the execution values in "vals"
        public Expression eval(HashMap<String, Expression> vals) {
            if (kind == ExpressionKind.NUMBER) { // use this instance directly
                return this;
            } else if (kind == ExpressionKind.SYMBOL) { // lookup the symbol in the value map
                return vals.get(v);
            } else {
                assert op != Operation.INP;
                Expression left_v = left.eval(vals);
                Expression right_v = right.eval(vals);
                Expression res = null;
                if (left_v.kind == ExpressionKind.NUMBER && right_v.kind == ExpressionKind.NUMBER) {
                    // Easy, compute the result directly
                    res = new Expression(num_op(left_v.num_v, right_v.num_v));
                } else { // all the other combinations, including trees, numbers and symbols
                    Expression the_number = null;
                    if (left_v.kind == ExpressionKind.NUMBER) {
                        the_number = left_v;
                    } else if (right_v.kind == ExpressionKind.NUMBER) {
                        the_number = right_v;
                    }
                    switch (op) {
                        case MUL:
                            if (the_number != null && the_number.num_v == 0) { // anything * 0 = 0
                                res = new Expression(0);
                            } else if (the_number != null && the_number.num_v == 1) { // x * 1 = 1 + x = x
                                res = the_number == left_v ? right_v : left_v;
                            }
                            break;
                        case ADD:
                            if (the_number != null && the_number.num_v == 0) { // x + 0 = 0 + x = x
                                res = the_number == left_v ? right_v : left_v;
                            }
                            break;
                        case SUB:
                            if (right_v.kind == ExpressionKind.NUMBER && right_v.num_v == 0) { // x - 0 = x
                                res = left_v;
                            }
                            break;
                        case DIV:
                            if (left_v.toString().equals(right_v.toString())) { // x / x = 1
                                res = new Expression(1);
                            } else if (right_v.kind == ExpressionKind.NUMBER && right_v.num_v == 1) { // x / 1 = x
                                res = left_v;
                            }
                            break;
                        case MOD:
                            if (left_v.toString().equals(right_v.toString())) { // x % x = 0
                                res = new Expression(0);
                            } else if (right_v.kind == ExpressionKind.NUMBER && right_v.num_v == 1) { // x % 1 = 0
                                res = new Expression(0);
                            }
                            break;
                        default:
                            assert false;
                    }
                }
                // Return a new expression with the evaluated values of the right and left operands
                return res == null ? new Expression(op, left_v, right_v) : res;
            }
        }

        // Return the limits (min_value, max_value) of this expression
        public Limits get_limits() {
            if (kind == ExpressionKind.NUMBER) {
                return new Limits(this.num_v, this.num_v);
            } else if (kind == ExpressionKind.SYMBOL) {
                assert v.charAt(0) == 'd'; // we can only return limits for digits
                return new Limits(1, 9);
            } else {
                Limits left_limits = left.get_limits();
                long min_left = left_limits.min;
                long max_left = left_limits.max;
                Limits right_limits = right.get_limits();
                long min_right = right_limits.min;
                long max_right = right_limits.max;
                long res_min = 0, res_max = 0;
                switch (op) {
                    case ADD:
                    case SUB:
                        if (op == Operation.SUB) { // x - delta = x + (-delta)
                            long temp = min_right;
                            min_right = -max_right;
                            max_right = -temp;
                        }
                        res_min = min_left + min_right;
                        res_max = max_left + max_right;
                        break;
                    case MOD:
                        assert min_right > 0 && max_right > 0;
                        res_min = 0;
                        res_max = Math.min(min_right, max_right) - 1;
                        break;
                    case MUL:
                        assert min_right > 0 && max_right > 0;
                        res_min = min_left * min_right;
                        res_max = max_left * max_right;
                        break;
                    case DIV:
                        assert min_right > 0 && max_right > 0;
                        long min_div = Math.min(min_right, max_right);
                        long max_div = Math.max(min_right, max_right);
                        res_min = min_left / max_div;
                        res_max = max_left / min_div;
                        break;
                    default:
                        assert false;
                }
                assert res_min <= res_max;
                return new Limits(res_min, res_max);
            }
        }

        // Return true if the given EQL condition is always false by analyzing the intervals of its operands
        public boolean eql_is_definitely_false() {
            assert op == Operation.EQL;
            Limits left_limits = left.get_limits();
            Limits right_limits = right.get_limits();
            return !left_limits.intersects(right_limits);
        }

        // Return true if the given NEQ condition is always true by analyzing the intervals of its operands
        public boolean neq_is_definitely_true() {
            assert op == Operation.NEQ;
            Limits left_limits = left.get_limits();
            Limits right_limits = right.get_limits();
            return !left_limits.intersects(right_limits);
        }

        // Set all the input digits found in this expression in the "m" set
        public void _analyze_digits(TreeSet<Integer> m) {
            if (kind == ExpressionKind.SYMBOL) {
                assert v.charAt(0) == 'd'; // we can only return limits for digits
                int dig_no = Integer.parseInt(v.substring(1));
                m.add(dig_no);
            } else if (kind == ExpressionKind.TREE) {
                left._analyze_digits(m);
                right._analyze_digits(m);
            }
        }

        // Wrapper for the above function
        public void analyze_digits(TreeSet<Integer> m) {
            assert kind == ExpressionKind.TREE && (op == Operation.EQL || op == Operation.NEQ);
            if (left.kind == ExpressionKind.SYMBOL) {
                assert right.kind == ExpressionKind.TREE;
                right._analyze_digits(m);
            } else {
                assert left.kind == ExpressionKind.TREE;
                left._analyze_digits(m);
            }
        }

        // Evaluate the expression with the given input digits
        public long eval_with_digits(int[] digs) {
            if (kind == ExpressionKind.NUMBER) {
                return num_v;
            } else if (kind == ExpressionKind.SYMBOL) {
                assert v.charAt(0) == 'd';
                return digs[Integer.parseInt(v.substring(1))];
            } else {
                long left_v = left.eval_with_digits(digs);
                long right_v = right.eval_with_digits(digs);
                return num_op(left_v, right_v);
            }
        }

        // Check the condition for the digit (which must be an EQL condition with a single digit on one side)
        // Return a (digit_numer, digit_value) pair
        public DigitValue check_digit_condition(int[] digs) {
            assert kind == ExpressionKind.TREE && op == Operation.EQL;
            int digit_no = 0, digit_val = 0;
            if (left.kind == ExpressionKind.SYMBOL) {
                assert right.kind == ExpressionKind.TREE;
                digit_no = Integer.parseInt(left.v.substring(1));
                digit_val = (int)right.eval_with_digits(digs);
            } else {
                assert left.kind == ExpressionKind.TREE;
                digit_no = Integer.parseInt(right.v.substring(1));
                digit_val = (int)left.eval_with_digits(digs);

            }
            return new DigitValue(digit_no, digit_val);
        }
    }

    // ****************************************************************************************************************
    // An isntruction keeps the operation types and its destination (first operand) and source (second operand),
    // with the exception of INP that takes a simple operand (the destination)

    class Instruction {
        public Operation op;
        public String op_str;
        public String dest;
        public String src;
        public long src_num;
        public boolean src_is_num;

        public Instruction(String op, String dest, String src) {
            op_str = op;
            this.op = str_to_op.get(op);
            this.dest = dest;
            this.src = src;
            try {
                src_num = Long.parseLong(src);
                src_is_num = true;
            } catch (Exception e) {
                src_num = 0;
                src_is_num = false;
            }
        }

        public void change_op(String new_op) {
            op_str = new_op;
            this.op = str_to_op.get(new_op);
        }

        public void change_src_num(long new_num) {
            assert src_is_num;
            src_num = new_num;
            src = Long.toString(new_num);
        }

        public String toString() {
            return this.op_str + " " + this.dest + " " + (this.src == null ? "" : this.src);
        }
    }

    // ****************************************************************************************************************
    // A generator for all the possible inputs to the final expression(s)

    class Generator {
        private int digits;                             // number of digits
        public int[] values;                            // currenet digit values
        private boolean overflowed;                     // true if this generator is done

        public Generator(int size) {
            digits = size;
            values = new int[size];
            // Initiaize generator with 1 except for the last position which should be a 0 for the next next() call
            for (int i = 0; i < size; i ++) {
                values[i] = 1;
            }
            values[size - 1] = 0;
            overflowed = false;
        }

        // Generate and return the next value
        public int[] next() {
            assert overflowed == false;
            boolean ok = false;
            if (values[digits - 1] == 9) { // overflowed last digit, find the previous digit that can be incremented
                for (int idx = digits - 2; idx >= 0; idx -= 1) {
                    if (values[idx] < 9) {
                        values[idx] += 1;
                        ok = true;
                        // Reset all the other digits to 1
                        for (int i = idx + 1; i < digits; i ++) {
                            values[i] = 1;
                        }
                        break;
                    }
                }
            } else {
                ok = true;
                values[digits - 1] += 1;
            }
            if (!ok) {
                overflowed = true;
                return null;
            } else {
                return values;
            }
        }
    }

    // ****************************************************************************************************************
    // Various utilities

    // Read input file and populate the internal Instructions array
    void read_input(String fname) throws FileNotFoundException {
        InputStream is = new FileInputStream(fname);
        Scanner sc = new Scanner(is, StandardCharsets.US_ASCII.name());
        Instruction prev_i = null;
        while (sc.hasNextLine()) {
            String l = sc.nextLine();
            String[] parts = l.trim().split(" ");
            Instruction i = new Instruction(parts[0], parts[1], parts.length == 3 ? parts[2] : null);
            boolean skip_add = false;
            // add x -num => sub x num
            if (i.op == Operation.ADD && i.src_is_num && i.src_num < 0) {
                i.change_op("sub");
                i.change_src_num(-i.src_num);
            }
            // Convert a sequence of consecutive EQL <a> <b> / EQL <a> [0|1] to a single EQL/NEQ as needed
            if (i.op == Operation.EQL && prev_i != null && prev_i.op == Operation.EQL && i.dest.equals(prev_i.dest) && i.src_is_num && (i.src_num == 0 || i.src_num == 1)) {
                skip_add = true;
                if (i.src_num == 0) {
                    prev_i.change_op("neq");
                }
            }
            if (!skip_add) {
                instructions.add(i);
                prev_i = i;
            }
        }
        sc.close();
        // This is still as ridiculous as it gets
        try {
            is.close();
        } catch (Exception e) {}
    }

    // Interpret the list of instructios starting from "start", accumulating conditions in "conds"
    void interpret(int start, int input_index, HashMap<String, Expression> vals, ArrayList<Expression> conditions) {
        for (int idx = start; idx < instructions.size(); idx ++) {
            Instruction i = instructions.get(idx);
            Expression res = null;
            if (i.op == Operation.INP) { // execute input instruction directly
                // Use "d<input_index>" as the notation for the input_index-th digit of the input
                res = new Expression(String.format("d%d", input_index));
                input_index ++;
            } else if (i.op == Operation.NEQ || i.op == Operation.EQL) {
                Expression left = new Expression(i.dest).eval(vals);
                Expression right = new Expression(i.src).eval(vals);
                // Split current execution path in two paths where the comparison has different values (0 or 1)
                // Make a copy of the current environment
                HashMap<String, Expression> vals_copy = new HashMap<>();
                vals.forEach((key, value) -> vals_copy.put(key, value));
                vals_copy.put(i.dest, new Expression(1)); // split for value 1
                // And a copy of the current conditions
                ArrayList<Expression> conditions_copy = new ArrayList<>();
                conditions.forEach((e) -> conditions_copy.add(e));
                conditions_copy.add(new Expression(i.op, left, right));
                // Split for condition true
                interpret(idx + 1, input_index, vals_copy, conditions_copy);
                // Continue on this execution for condition false
                conditions.add(new Expression(i.op == Operation.EQL ? Operation.NEQ : Operation.EQL, left, right));
                res = new Expression(0);
            } else {
                res = new Expression(i.op, new Expression(i.dest), new Expression(i.src)).eval(vals);
            }
            assert res != null;
            vals.put(i.dest, res);
        }
        // After all the instructions ran, the final value of "z" is in vals[z]
        // First check if the value can ever be 0
        Limits l = vals.get("z").get_limits();
        if (l.min > 0 || l.max < 0) {
            return;
        }
        // Then bail out if any of the conditions can never be true
        for(Expression e: conditions) {
            if (e.op == Operation.EQL && e.eql_is_definitely_false()) {
                return;
            }
        }
        // This result is OK, but simplify the conditions by removing the != conditions that are always true
        // (for example digit != 12)
        ArrayList<Expression> filtered_conditions = new ArrayList<>();
        for(Expression e: conditions) {
            if (e.op == Operation.EQL || !e.neq_is_definitely_true()) {
                filtered_conditions.add(e);
            }
        }
        all_results.add(new Result(filtered_conditions, vals.get("z")));
    }

    // Return the value of the given array as a long number
    long arr2long(int[] a) {
        long v = 0;
        for (int i = 0; i < a.length; i ++) {
            v = v * 10 + (long)a[i];
        }
        return v;
    }

    // ****************************************************************************************************************
    // Entry point

    void solve() throws FileNotFoundException {
        read_input("input.txt");
        // Initial environment
        HashMap<String, Expression> vals = new HashMap<>();
        vals.put("w", new Expression(0));
        vals.put("x", new Expression(0));
        vals.put("y", new Expression(0));
        vals.put("z", new Expression(0));
        // Interpret the program on all possible paths
        interpret(0, 0, vals, new ArrayList<Expression>());
        // At this point, all_result should have a single entry
        assert all_results.size() == 1;
        Expression e = all_results.get(0).z;
        ArrayList<Expression> conds = all_results.get(0).conditions;

        // Find the list of all input variables in the conditions and the body of the expression. These are the variables
        // that we'll have to go through in order to find the minimum/maximum values.
        TreeSet<Integer> used = new TreeSet<>();
        e.analyze_digits(used);
        for (Expression c: conds) {
            c.analyze_digits(used);
        }
        // This is the "problem size": how many digits we actually need to iterate
        Integer[] used_digs = used.stream().toArray(Integer[] ::new);
        int input_size = used.size();
        //System.out.println(String.format("Input size: %d", input_size));
        // Map the digits in use to the actual digits returned by the generator
        HashMap<Integer, Integer> dig_map = new HashMap<>();
        for (int i = 0; i < used_digs.length; i ++) {
            dig_map.put(i, used_digs[i]);
        }
        // Does the expression actually need to be evaluated? If its min == max == 0, it means it's always 0 for all digits.
        Limits l = e.get_limits();
        boolean must_eval_expr = l.min != 0 || l.max != 0;

        // Generate all the input digits and check the conditions/expression (if needed)
        Generator g = new Generator(input_size);
        int[] digs = new int[14];
        long max_v = 0, min_v = Long.MAX_VALUE;
        while (true) {
            // Get the current digits from iterator
            int[] i_digs = g.next();
            if (i_digs == null) {
                break;
            }
            // Map the iterator digits to the 14-digits array needed by the puzzle
            dig_map.forEach((key, value) -> digs[value] = i_digs[key]);
            // Evaluate and check each condition
            boolean ok = true;
            for (Expression c: conds) {
                DigitValue d = c.check_digit_condition(digs);
                if (d.val <= 0 || d.val > 9) { // invalid digit
                    ok = false;
                    break;
                }
                // Digit OK, store it
                digs[d.dig_no] = d.val;
            }
            if (!ok) {
                continue;
            }
            // Evaluate the expression if needed and skip if its value is not 0
            if (must_eval_expr && e.eval_with_digits(digs) != 0) {
                continue;
            }
            // We found a solution!
            long temp = arr2long(digs);
            if (min_v > temp) {
                min_v = temp;
            }
            if (max_v < temp) {
                max_v = temp;
            }
        }

        // Finally
        System.out.println(String.format("Part 1: %d", max_v));
        System.out.println(String.format("Part 2: %d", min_v));
    }

    public static void main(String[] args) throws FileNotFoundException {
        new Solution().solve();
    }
}
