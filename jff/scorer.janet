(import fzy :prefix "" :export true)

(defn match-and-score [d s &opt keywords?]
  (if keywords?
    (seq [[i _] :in d
          :let [sc (sum (map |(score $0 i) (string/split " " (string/trim s))))]
          :when (and sc (> sc score-min))]
      [i sc])
    (seq [[i _] :in d
          :let [sc (score s i)]
          :when (and sc (> sc score-min))]
      [i sc])))

(defn match-n-sort [d s &opt keywords?]
  (if (empty? d) (break d))
  (sort-by |(- ($ 1))
           (match-and-score d s keywords?)))
