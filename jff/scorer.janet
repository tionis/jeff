(import /build/fzy :prefix "" :export true)

(def score-min math/-inf)

(defn match-and-score [d s]
  (seq [[i _] :in d
        :let [sc (and (has-match s i) (score s i))]
        :when (and sc (> sc score-min))]
    [i sc]))

(defn match-n-sort [d s]
  (if (empty? d) (break d))
  (sort-by |(- ($ 1))
           (match-and-score d s)))
