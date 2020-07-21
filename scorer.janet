# redone as struct
(def score-min math/-inf)
(def score-max math/inf)

(def score-gap-leading -0.005)
(def score-gap-trailing -0.005)
(def score-gap-inner -0.01)
(def score-match-consecutive 1.0)
(def score-match-slash 0.9)
(def score-match-word 0.8)
(def score-match-capital 0.7)
(def score-match-dot 0.6)

(defn- is-lower [s] (= s (string/ascii-lower s)))
(defn- is-upper [s] (= s (string/ascii-upper s)))

(defn- precompute-bonus [haystack]
  (def m (length haystack))
  (def match-bonus (array/new m))
  (var last-ch "/")
  (for i 0 m
    (def ch (string/from-bytes (haystack i)))
    (put match-bonus i
         (cond
           (= last-ch "/") score-match-slash
           (or (= last-ch "-") (= last-ch " ") (= last-ch "_")) score-match-word
           (= last-ch ".") score-match-dot
           (and (is-lower last-ch) (is-upper ch)) score-match-capital
           0))
    (set last-ch ch))
  match-bonus)

(defn compute [needle haystack D M]
  (def n (length needle))
  (def m (length haystack))
  (def lower-needle (string/ascii-lower needle))
  (def lower-haystack (string/ascii-lower haystack))

  (def match-bonus (precompute-bonus haystack))

  (for i 0 n
    (put D i (array/new m))
    (put M i (array/new m))
    (var prev-score score-min)
    (var gap-score (if (= i (dec n)) score-gap-trailing score-gap-inner))
    (for j 0 m
      (if (= (lower-needle i) (lower-haystack j))
        (do
          (var score score-min)
          (cond
            (zero? i) (set score (+ (* j score-gap-leading) (match-bonus j)))
            (pos? j) (set score (max (+ (get-in M [(dec i) (dec j)]) (match-bonus j))
                                     (+ (get-in D [(dec i) (dec j)]) score-match-consecutive))))
          (put-in D [i j] score)
          (put-in M [i j] (set prev-score (max score (+ prev-score gap-score)))))
        (do
          (put-in D [i j] score-min)
          (put-in M [i j] (set prev-score (+ prev-score gap-score))))))))


(defn score [needle haystack]
  (def n (length needle))
  (def m (length haystack))
  (when (or (zero? n) (zero? m)) (break score-min))
  (when (= n m) (break score-max))
  (when (> m 1024) (break score-min))
  (def D (array/new n))
  (def M (array/new n))
  (compute needle haystack D M)
  (get-in M [(dec n) (dec m)]))

(defn has-match [needle haystack]
  (def needle (string/ascii-lower needle))
  (def haystack (string/ascii-lower haystack))
  (def l (length needle))
  (var j 0)
  (for i 0 l
    (set j (string/find (string/from-bytes (needle i)) haystack j))
    (when (nil? j) (break false))
    (set j (inc j)))
  true)


#(defn score [needle haystack]
#(def n (length needle))
#(def m (length haystack))
#(def positions (array/new n))
#(when (or (zero? n) (zero? m)) (break positions))
#(when (= n m)
#(for i 0 (dec n)
#(put positions i i))
#(break positions))
#(when (> m 1024) (break positions))
#(def d (array/new n))
#(def m (array/new n))
#(compute needle haystack d m)
#)

