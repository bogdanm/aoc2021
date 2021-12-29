(module
  ;; Memory layout:
  ;;   input_size * 8 - input data (as an array of f64 numbers)
  ;;   9 * 8 - counter array (as an array of f64 numbers)
  (memory $mem 1)

  ;; Total arguments set via set_input
  (global $tot_args (mut i32) (i32.const 0))

  (func $solve (param $days i32) (result f64)
    ;; Index of our counter array
    (local $cnt_arr_idx i32)
    ;; Loop counters
    (local $loop_cnt_1 i32)
    (local $loop_cnt_2 i32)
    ;; Temporary variables
    (local $tempf64_1 f64)
    (local $tempi32_1 i32)
    (local $tempn0 f64)

    ;; Compute first location of the counter array
    (set_local $cnt_arr_idx (i32.mul (get_global $tot_args) (i32.const 8)))

    ;; Set the counter array to 0 initially
    (set_local $loop_cnt_1 (i32.const 0))
    (loop $init0
      (f64.store (i32.add (get_local $cnt_arr_idx) (i32.mul (get_local $loop_cnt_1) (i32.const 8))) (f64.const 0))
      ;; Next iteration
      (set_local $loop_cnt_1 (i32.add (get_local $loop_cnt_1) (i32.const 1)))
      (br_if $init0 (i32.lt_s (get_local $loop_cnt_1) (i32.const 9)))
    )

    ;; Apply the input by incrementing the initial counters
    (set_local $loop_cnt_1 (i32.const 0))
    (loop $initadd
      ;; Load number from input
      (set_local $tempf64_1 (f64.load (i32.mul (get_local $loop_cnt_1) (i32.const 8))))
      ;; Convert input to an index
      (set_local $tempi32_1 (i32.add (get_local $cnt_arr_idx) (i32.mul (i32.trunc_s/f64 (get_local $tempf64_1)) (i32.const 8))))
      ;; Increment counter at this index
      (f64.store (get_local $tempi32_1) (f64.add (f64.load (get_local $tempi32_1)) (f64.const 1)))
      ;; Next iteration
      (set_local $loop_cnt_1 (i32.add (get_local $loop_cnt_1) (i32.const 1)))
      (br_if $initadd (i32.lt_s (get_local $loop_cnt_1) (get_global $tot_args)))
    )

    ;; Run the algorithm for the given number of days
    (set_local $loop_cnt_1 (i32.const 0))
    (loop $mainloop
      ;; Remember the value of counter 0 for later use
      (set_local $tempn0 (f64.load (get_local $cnt_arr_idx)))
      ;; Shift all values in the counter array to the left
      (set_local $loop_cnt_2 (i32.const 0))
      (loop $shift
        ;; Compute current index into count array
        (set_local $tempi32_1 (i32.add (get_local $cnt_arr_idx) (i32.mul (get_local $loop_cnt_2) (i32.const 8))))
        ;; array[i] = arr[i + 1]
        (i64.store (get_local $tempi32_1) (i64.load (i32.add (get_local $tempi32_1) (i32.const 8))))
        ;; Next iteration
        (set_local $loop_cnt_2 (i32.add (get_local $loop_cnt_2) (i32.const 1)))
        (br_if $shift (i32.lt_s (get_local $loop_cnt_2) (i32.const 8)))
      )
      ;; Apply the initial zeros (in $tempn0) to the array: first increment sixes
      (set_local $tempi32_1 (i32.add (get_local $cnt_arr_idx) (i32.const 48))) ;; 6 elements * 8 bytes = index 48
      (f64.store (get_local $tempi32_1) (f64.add (f64.load (get_local $tempi32_1)) (get_local $tempn0)))
      ;; Then set eights to the new population count
      (f64.store (i32.add (get_local $cnt_arr_idx) (i32.const 64)) (get_local $tempn0))
      ;; Next iteration
      (set_local $loop_cnt_1 (i32.add (get_local $loop_cnt_1) (i32.const 1)))
      (br_if $mainloop (i32.lt_s (get_local $loop_cnt_1) (get_local $days)))
    )

    ;; Compute and return the sum of the elements in the counter array (which is the final solution)
    ;; The result is accumulated in "tempn0"
    (set_local $tempn0 (f64.const 0))
    (set_local $loop_cnt_1 (i32.const 0))
    (loop $resloop
      ;; Read current value
      (set_local $tempf64_1 (f64.load (i32.add (get_local $cnt_arr_idx) (i32.mul (get_local $loop_cnt_1) (i32.const 8)))))
      (set_local $tempn0 (f64.add (get_local $tempn0) (get_local $tempf64_1)))
      ;; Next iteration
      (set_local $loop_cnt_1 (i32.add (get_local $loop_cnt_1) (i32.const 1)))
      (br_if $resloop (i32.lt_s (get_local $loop_cnt_1) (i32.const 9)))
    )
    (get_local $tempn0)
  )

  ;; Set a single input of the algorithm
  (func $add_input (param $v f64)
    (local $mem_idx i32)
    ;; Compute index in memory based on current index
    (set_local $mem_idx (i32.mul (get_global $tot_args) (i32.const 8)))
    (f64.store (get_local $mem_idx) (get_local $v))
    ;; Increment input index
    (set_global $tot_args (i32.add (i32.const 1) (get_global $tot_args)))
  )

  ;; Exports
  (export "solve" (func $solve))
  (export "add_input" (func $add_input))
)