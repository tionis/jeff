(import jermbox :as tb)
(import spork/sh)
(import ./utf8)
(use ./scorer)

(defn fzf/choose [choices &named prmpt preview-command ansi-color multi]
  (def args @["fzf" "--read0" "--print0"])
  (def choices-stream
    (case (type choices)
      #:core/stream choices
      #:string (let [pipes (os/pipe)]
      #             (ev/write (pipes 1) choices)
      #             (ev/close (pipes 1))
      #             (pipes 0))
      :tuple (let [pipes (os/pipe)]
                   (ev/write (pipes 1) (string/join choices "\0"))
                   (ev/close (pipes 1))
                   (pipes 0))
      :array (let [pipes (os/pipe)]
                   (ev/write (pipes 1) (string/join choices "\0"))
                   (ev/close (pipes 1))
                   (pipes 0))
    (error "unsupported choices type")))
  (when preview-command (array/push args "--preview" preview-command))
  (when ansi-color (array/push args "--ansi"))
  (when prmpt (array/push args "--prompt" prmpt))
  (when multi (array/push args "--multi"))
  (try
    (do (def proc (os/spawn args :px {:out :pipe :in choices-stream}))
        (def out (get proc :out))
        (def buf @"")
        (ev/gather
          (:read out :all buf)
          (:wait proc))
        (if multi
          (string/split "\0" (string/trimr buf))
          (string/trimr buf)))
    ([err] (os/exit 1))))

# todo document
(defn jeff/choose
  [choices &named prmpt keywords?]
  (default prmpt "> ")
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
      (def msg (utf8/to-codepoints message))
      (def rp (reverse positions))
      (var np (array/pop rp))

      (for c 0 (min cols (length msg))
        (def p? (= c np))
        (def bg (if p? (do
                         (if (empty? rp) (set np (array/pop rp)))
                         (if inv? tb/yellow lbg)) lbg))
        (def fg (bor (if inv? lfg (if p? tb/yellow lfg))
                     (if (= style :bold) tb/bold 0)))
        (tb/change-cell (+ col c) row (msg c) fg bg)))

    (defn show-ui []
      (tb/clear)
      (to-cells
        (if input?
          (string/format "%s%s\u2588"
                         prmpt (string s))
          (string/format "%d/%d %s%s\u2588"
                         (length sd) lc prmpt (string s)))
        0 0 :bold)
      (for i 0 (min (length sd) rows)
        (def [term score positions] (get sd i))
        (to-cells term 0 (inc i)
                  (if (= pos i) :inv)
                  positions))
      (tb/present))

    (show-ui)

    (defn reset-pos [] (set pos 0))
    (defn inc-pos [] (if (> (dec (length sd)) pos) (++ pos) (set pos 0)))
    (defn dec-pos [] (if (pos? pos) (-- pos) (set pos (dec (length sd)))))
    (defn quit [] (tb/shutdown) (os/exit 0))

    (defn add-char [c]
      (reset-pos)
      (buffer/push-string s (utf8/from-codepoints [c]))
      (set sd (or (get cache (freeze s)) (match-n-sort sd s keywords?)))
      (put cache (freeze s) (array/slice sd)))

    (defn complete []
      (reset-pos)
      (when (pos? (length sd))
        (set s (buffer (get-in sd [pos 0])))
        (set sd (match-n-sort sd s keywords?))))

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
          (not (empty? s)) (set sd (or (get cache (freeze s))
                                       (match-n-sort choices s keywords?)))
          (set sd choices))))

    (defn actions [key]
      (def ba
        @{tb/key-space |(add-char (chr " "))
          tb/key-backspace2 erase-last tb/key-ctrl-h erase-last
          tb/key-esc quit tb/key-ctrl-c quit
          tb/key-enter |(set res s)})
      (if-let [afn
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

(defn choose
  [choices &named prmpt keywords? use-fzf multi]
  (default use-fzf (truthy? (os/getenv "TMUX"))) # TODO hotfix for #12
  (if (and (or use-fzf multi)# when use-fzf check if fzf is available, if not fall back to normal matching
           (= (os/execute ["fzf" "--version"] :p {:out (sh/devnull) :err (sh/devnull)}) 0))
    (fzf/choose choices :prmpt prmpt :multi multi)
    (jeff/choose choices :prmpt prmpt :keywords? keywords?)))

(defn input [prmpt] (choose prmpt []))
