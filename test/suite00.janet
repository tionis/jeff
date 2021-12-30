(use spork/test)
(use /jff/scorer)

(start-suite 0)

(assert (empty? (match-n-sort [] "s")))

(assert (deep= (match-n-sort [["asd"] ["sada"] ["dsa"]] "s")
               @[["sada" 0.885] ["asd" -0.01] ["dsa" -0.01]])
        "match-n-sort")

(assert (deep= (positions "s" "has")
               @[2])
        "positions")

(assert (has-match "s" "as")
        "has-match")

(assert-not (has-match "Z" "as")
            "has not match")

(end-suite)
