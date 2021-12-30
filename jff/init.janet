(import jermbox :as tb)
(import utf8)
(import spork/argparse :prefix "")

(import /jff/scorer :prefix "")


(def argparse-params
  ["Janet Fuzzy Finder - get through some stdout almost omnisciently and friendly.
   "
   "file" {:kind :option
           :short "f"
           :help "Read a file rather than stdin for choices."}
   "prompt" {:kind :option
             :short "r"
             :help "Change the prompt. Default: '> '."
             :default "> "}
   "prepare" {:kind :option
              :short "e"
              :help "Janet function defition to transform each line with. Default identity."}
   "grammar" {:kind :option
              :short "g"
              :help "PEG grammar to match with the result. Default nil which means  no matching."}
   "code" {:kind :option
           :short "c"
           :help "Janet function definition to transform result with. The selected choice or the PEG match if grammar provided. Default is print"}
   "program" {:kind :option
              :short "p"
              :help "File with code which must have three function preparer, matcher and transformer."}])

(defn choose [prmt choices]
  (def choices (map |[$ 0] choices))
  (var res nil)
  (def input? (empty? choices))

  (defer (tb/shutdown)
    (tb/init)

    (def cols (tb/width))
    (def rows (tb/height))
    (def e (tb/init-event))
    (var pos 0)
    (var s @"")
    (var sd choices)
    (def lc (length choices))
    (def cache (table))

    (defn to-cells [message &opt col row style positions]
      (default col 0)
      (default row 0)
      (default positions [])

      (def inv? (= style :inv))
      (def lfg (if inv? tb/black tb/white))
      (def lbg (if inv? tb/white tb/black))
      (def msg (utf8/decode message))
      (def rp (reverse positions))
      (var np (array/pop rp))

      (for c 0 (min cols (length msg))
        (def p? (= c np))
        (def bg (if p? (do
                         (unless (empty? rp) (set np (array/pop rp)))
                         (if inv? tb/yellow lbg)) lbg))
        (def fg (bor (if inv? lfg (if p? tb/yellow lfg))
                     (if (= style :bold) tb/bold 0)))
        (tb/change-cell (+ col c) row (msg c) fg bg)))

    (defn show-ui []

      (tb/clear)
      (to-cells
        (if input?
          (string/format "%s%s\u2588"
                         prmt (string s))
          (string/format "%d/%d %s%s\u2588"
                         (length sd) lc prmt (string s)))
        0 0 :bold)
      (for i 0 (min (length sd) rows)
        (def [term score positions] (get sd i))
        (to-cells term 0 (inc i)
                  (when (= pos i) :inv)
                  positions))
      (tb/present))

    (show-ui)

    (defn reset-pos [] (set pos 0))
    (defn inc-pos [] (if (> (dec (length sd)) pos) (++ pos) (set pos 0)))
    (defn dec-pos [] (if (pos? pos) (-- pos) (set pos (dec (length sd)))))
    (defn quit [] (tb/shutdown) (os/exit 1))

    (defn add-char [c]
      (reset-pos)
      (buffer/push-string s (utf8/encode [c]))
      (set sd (or (get cache (freeze s)) (match-n-sort sd s)))
      (put cache (freeze s) (array/slice sd)))

    (defn complete []
      (reset-pos)
      (when (pos? (length sd))
        (set s (buffer (get-in sd [pos 0])))
        (set sd (match-n-sort sd s))))

    (defn erase-last []
      (reset-pos)
      (when-let [ls (last s)]
        (buffer/popn s
                     (cond
                       (> ls 0xE0) 4
                       (> ls 0xC0) 3
                       (> ls 0x7F) 2
                       1))
        (cond
          (= (length sd) lc) (break)
          (not (empty? s)) (set sd (or (get cache (freeze s)) (match-n-sort choices s)))
          (set sd choices))))

    (defn actions [key]
      (def ba
        @{tb/key-space |(add-char (chr " "))
          tb/key-backspace2 erase-last tb/key-ctrl-h erase-last
          tb/key-esc quit tb/key-ctrl-c quit
          tb/key-enter |(set res s)})
      (when-let [afn
                 ((if (not input?)
                    (merge ba
                           {tb/key-ctrl-n inc-pos tb/key-ctrl-j inc-pos
                            tb/key-arrow-down inc-pos
                            tb/key-ctrl-p dec-pos tb/key-ctrl-k dec-pos
                            tb/key-arrow-up dec-pos
                            tb/key-tab complete
                            tb/key-enter |(set res (or (get-in sd [pos 0]) s))})
                    ba) key)]
        (afn)))

    (while (and (nil? res) (tb/poll-event e))
      (def [c k] [(tb/event-character e) (tb/event-key e)])
      (if (zero? c) (actions k) (add-char c))
      (show-ui))

    (tb/clear))
  res)

(defn input [prmt] (choose prmt []))

(defn main [_ &]
  (when-let [parsed (argparse ;argparse-params)]
    (let [{"file" file
           "prompt" prmt
           "prepare" prepare
           "grammar" grammar
           "code" code
           "program" program} parsed]

      (var preparer identity)
      (var matcher identity)
      (var transformer print)

      (when grammar (set matcher |(peg/match (parse grammar) $)))
      (when code (set transformer (eval (parse code))))
      (when prepare (set preparer (eval (parse prepare))))

      (when-let [program (and program (dofile program))]
        (when-let [prepare-fn (get-in program ['prepare :value])] (set preparer prepare-fn))
        (when-let [grammar-def (get-in program ['grammar :value])] (set matcher |(peg/match grammar-def $)))
        (when-let [transform-fn (get-in program ['transform :value])] (set transformer transform-fn)))

      (def file (if file (file/open file :r) stdin))
      (->> (seq [l :iterate (:read file :line)] (preparer (string/trim l)))
           (filter |(not (empty? $)))
           (choose prmt)
           (matcher)
           (transformer)))))
