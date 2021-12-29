import kotlinx.cinterop.*
import platform.posix.*

// Type of packets
enum class Packet {
    ADD, PRODUCT, MINIMUM, MAXIMUM, LITERAL, GT, LT, EQ
}

// This class takes a hex string and interprets it as a binary stream
class BitStream(var s: String) {
    // Index of current bit in the stream
    var crt_bit_idx = 0
    // Maximum index
    val max_bit_idx = s.length * 8
    // Data as an array of integers
    val data = Array(s.length) {i -> s[i].digitToInt(16)}

    // Return the next bit in the stream
    fun get_next_bit(): Int {
        check(crt_bit_idx < max_bit_idx) {"Bit index out of bounds"}
        // Position in the data array
        val m_idx = crt_bit_idx / 4
        // Bit mask (MSB first)
        val mask = 1 shl (3 - (crt_bit_idx % 4))
        // Advance to next bit
        crt_bit_idx += 1
        return if ((data[m_idx] and mask) != 0) 1 else 0
    }

    // Get next number from the specified number of bits
    fun get_next_number(nbits: Int): Int {
        var n = 0
        for (i in 1..nbits) n = n * 2 + get_next_bit()
        return n
    }

    // Reset the stream by positioning its bit index at the beginning
    fun reset() {
        crt_bit_idx = 0
    }
}

// Solver for part 1: return the version field of a LITERAL packet or the sum of all versions otherwise
fun part1(kind: Packet, version: Long, c: Collection<Long>): Long {
    return if (kind == Packet.LITERAL) version else (version + c.sum())
}

// Solver for part 2: intepret packet type and execute instructions
fun part2(kind: Packet, @Suppress("UNUSED_PARAMETER") version: Long, c: Collection<Long>): Long {
    return when (kind) {
        Packet.LITERAL, Packet.ADD -> c.sum()
        Packet.PRODUCT -> c.fold(1, {a: Long, b: Long -> a * b})
        Packet.MINIMUM -> c.minOrNull() ?: 0
        Packet.MAXIMUM -> c.maxOrNull() ?: 0
        Packet.LT -> if (c.elementAt(0) < c.elementAt(1)) 1L else 0L
        Packet.GT -> if (c.elementAt(0) > c.elementAt(1)) 1L else 0L
        Packet.EQ -> if (c.elementAt(0) == c.elementAt(1)) 1L else 0L
    }
}

// This function is used for solving both parts. It receives a part-specific "f" function that is ised
// to manipulate the data for each part (as above)
fun solver(b: BitStream, f: (Packet, Long, Collection<Long>) -> Long): Long {
    val version = b.get_next_number(3).toLong()
    val kind = Packet.values()[b.get_next_number(3)]
    var res: Long // final result of the function
    if (kind == Packet.LITERAL) { // literal packet, read the number
        var n = 0L
        while (true) {
            val is_last = b.get_next_bit() == 0
            n = n * 16 + b.get_next_number(4).toLong()
            if (is_last) break
        }
        res = f(kind, version, listOf(n))
    } else { // operator, parse recursively
        val c = ArrayList<Long>() // the result of all children is accumulated here
        if (b.get_next_bit() == 0) { // total length in bits, read until all the bits are processed
            val total_bits = b.get_next_number(15)
            val crt_idx = b.crt_bit_idx
            while (b.crt_bit_idx - crt_idx < total_bits) c.add(solver(b, f))
        } else { // number of subpackets, process that number of packets
            val num_subs = b.get_next_number(11)
            for (i in 1..num_subs) c.add(solver(b, f))
        }
        res = f(kind, version, c)
    }
    return res
}

// Happily borrowed from https://nequalsonelifestyle.com/2020/11/16/kotlin-native-file-io/
fun read_input(path: String): String {
    val return_buffer = StringBuilder()
    val file = fopen(path, "r") ?: throw IllegalArgumentException("Cannot open input file $path")

    try {
        memScoped {
            val read_buffer_len = 64 * 1024
            val buffer = allocArray<ByteVar>(read_buffer_len)
            var line = fgets(buffer, read_buffer_len, file)?.toKString()
            while (line != null) {
                return_buffer.append(line)
                line = fgets(buffer, read_buffer_len, file)?.toKString()
            }
        }
    } finally {
        fclose(file)
    }

    return return_buffer.toString().trim()
}

fun main() {
    val data = read_input("input.txt")
    val b = BitStream(data)
    println("Part 1: ${solver(b, ::part1)}") // is it just me or this ::func syntax is really weird?
    b.reset()
    println("Part 2: ${solver(b, ::part2)}")
}
