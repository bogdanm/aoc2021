#lang racket

; This structure defines the type of a single element in the data array:
; a number and a "this octopus already flashed in this step" flag
(struct el (num flashed) #:mutable)

; Convert each char in "s" to an "el"
(define (line->data s)
  (for/list ([ch (in-string s)])
    (el (- (char->integer ch) (char->integer #\0)) #f)))

; Read each line in the input data and return a list of 'el' structures
(define (read_input filename)
  (call-with-input-file filename
    (lambda (p)
      (let loop ([line (read-line p)] [result '()])
        (if (eof-object? line)
          (reverse result)
          (loop (read-line p) (append (reverse (line->data line)) result)))))))

; Find and return the number of flashes in the current input data
(define (find_flashes data)
  ; Return true if the index is valid, false otherwise
  (define (valid y x) (and (>= y 0) (< y 10) (>= x 0) (< x 10)))
  ; Convert (y, x) coordinated to an array index
  (define (crd2idx y x) (+ x (* 10 y)))
  ; Return the y coordinate from an index
  (define (get_y idx) (floor (/ idx 10)))
  ; Return the x coordinate from an index
  (define (get_x idx) (modulo idx 10))
  ; Increment the number at index if the coordinates are valid and the cell didn't already flash
  (define (inc y x)
    (let ([idx (+ x (* 10 y))])
      (cond [(valid y x) ; coordinats must be valid
        (let ([e (list-ref data idx)])
          (cond [(equal? (el-flashed e) #f) ; cell must be unflashed
            (set-el-num! e (add1 (el-num e)))]))])))
  (let loop ([idx 0] [flashes 0])
    (if (= idx 100)
      flashes
      (loop (add1 idx) (+ flashes (let ([y (get_y idx)] [x (get_x idx)] [e (list-ref data idx)])
        (cond [(> (el-num e) 9)
          (set-el-flashed! e #t) ; mark this cell as "flashed"
          (set-el-num! e 0) ; also reset its counter to 0
          ; Now increment all the valid neighbors that didn't already flash
          (inc y (- x 1)) ; left
          (inc y (+ x 1)) ; right
          (inc (- y 1) x) ; top
          (inc (+ y 1) x) ; bottom
          (inc (- y 1) (- x 1)) ; nw
          (inc (- y 1) (+ x 1)) ; ne
          (inc (+ y 1) (+ x 1)) ; se
          (inc (+ y 1) (- x 1)) ; sw
          1]
        [else 0])))))))

; Run a single step
(define (step data)
  ; First step: set "flashed" to false in all elements and increment their counter by 1
  (for ([e data])
    (set-el-flashed! e #f)
    (set-el-num! e (add1 (el-num e))))
  ; Keep on watching flashes until no more flashes are detected
  (let loop ([flashes 0])
    (let ([new_flashes (find_flashes data)])
      (if (equal? new_flashes 0)
        flashes
        (loop (+ flashes new_flashes))))))

; Return the sum of all numbers in the input
(define (data_sum data)
  (apply + (map (lambda (e) (el-num e)) data)))

; Entry point: read data and solve both parts
(let ([data (read_input "input.txt")])
  (let loop ([total 0] [idx 0] [all_flashed #f])
    (let* ([temp (step data)] [inc (if (< idx 100) temp 0)])
      (if (and (>= idx 100) all_flashed) ; found both conditions, print solution and exit
        (printf "Part 1: ~s~nPart 2: ~s~n" total all_flashed)
        (cond [(= 0 (data_sum data)) ; this means that everyone flashed, so remember the index if not already set
          (loop (+ total inc) (add1 idx) (if (equal? all_flashed #f) (add1 idx) all_flashed))]
        [else (loop (+ total inc) (add1 idx) all_flashed)])))))