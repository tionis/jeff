(use spork/test)
(use ../jeff/scorer)

(start-suite 0)

(assert (empty? (match-n-sort [] "s")))

(assert (deep= (match-n-sort [["asd"] ["sada"] ["dsa"]] "s")
               @[["sada" 0.885] ["asd" -0.01] ["dsa" -0.01]])
        "match-n-sort")

(end-suite)
