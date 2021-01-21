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
  (var last-ch 47)
  (seq [i :in haystack
        :after (set last-ch i)]
    (cond
      (= last-ch 47) score-match-slash
      (or (= last-ch 45) (= last-ch 32) (= last-ch 95)) score-match-word
      (= last-ch 46) score-match-dot
      (and (is-lower (string/from-bytes last-ch))
           (is-upper (string/from-bytes i))) score-match-capital
      0)))

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
      (if (= (in lower-needle i) (in lower-haystack j))
        (let [score
              (cond
                (zero? i) (+ (* j score-gap-leading) (match-bonus j))
                (pos? j) (max (+ (get-in M [(dec i) (dec j)] score-min)
                                 (match-bonus j))
                              (+ (get-in D [(dec i) (dec j)] score-min)
                                 score-match-consecutive))
                score-min)]
          (put-in D [i j] score)
          (put-in M [i j] (set prev-score (max (or score math/-inf)
                                               (+ prev-score gap-score)))))
        (do
          (put-in D [i j] score-min)
          (put-in M [i j] (set prev-score (+ prev-score gap-score))))))))


(defn score [needle haystack]
  (def n (length needle))
  (def m (length haystack))
  (if (or (zero? n) (zero? m)) (break score-min))
  (if (= n m) (break score-max))
  (if (> m 1024) (break score-min))
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
    (if (nil? j) (break false))
    (set j (inc j)))
  j)

(defn positions [needle haystack]
  (def n (length needle))
  (def m (length haystack))
  (def positions (array/new n))
  (when (or (zero? n) (zero? m)) (break positions))
  (when (= n m)
    (for i 0 (dec n)
      (put positions i i))
    (break positions))
  (if (> m 1024) (break positions))
  (def D (array/new n))
  (def M (array/new n))
  (compute needle haystack D M)
  (var match_required false)

  (var j (dec m))
  (loop [i :down-to [(dec n) 0]]
    (while (>= j 0)
      (let [Dij (get-in D [i j])
            Mij (get-in M [i j])]
        (when (and (not (= Dij score-min))
                   (or match_required (= Dij Mij)))
          (set match_required
               (and (pos? i) (pos? j)
                    (= Mij (+ (get-in D [(dec i) (dec j)])
                              score-match-consecutive))))
          (put positions i j)
          (-- j)
          (break)))
      (-- j)))

  positions)

(defn match-n-sort [d s]
  (when (empty? d) (break d))
  (->>
    d
    (reduce
      (fn [a [i _]]
        (let [sc (and (has-match s i) (score s i))]
          (if (and sc (> sc score-min))
            (array/push a [i sc (positions s i)])
            a)))
      (array/new (length d)))
    (sort-by |(- ($ 1)))))
