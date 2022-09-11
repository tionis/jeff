(import notcurses :as nc)
(import utf8)
(use ./scorer)

# todo document
(defn choose
  [prmt choices]
  (def choices (map |[$ 0] choices))
  (var res nil)
  (def input? (empty? choices))
  (def black [0 0 0])
  (def white [255 255 255])

  (def nc (nc/init))
  (defer (nc/stop nc)
    (def np (nc/stdplane nc))

    (def cols (nc/dim-y np))
    (def rows (nc/dim-x np))
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
      (def lfg (if inv? black white))
      (def lbg (if inv? white black))

      (nc/putstr-yx np col row message))

    (defn show-ui []
      (nc/erase np)
      (to-cells
        (if input?
          (string/format "%s%s\u2588"
                         prmt (string s))
          (string/format "%d/%d %s%s\u2588"
                         (length sd) lc prmt (string s)))
        0 0 :bold)

      (nc/render nc))

    (show-ui)

    (defn reset-pos [] (set pos 0))
    (defn inc-pos [] (if (> (dec (length sd)) pos) (++ pos) (set pos 0)))
    (defn dec-pos [] (if (pos? pos) (-- pos) (set pos (dec (length sd)))))
    (defn quit [] (nc/stop nc) (os/exit 0))

    (defn add-char [c]
      (reset-pos)
      (buffer/push-string s c)
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
          (not (empty? s)) (set sd (or (get cache (freeze s))
                                       (match-n-sort choices s)))
          (set sd choices))))

    (defn actions [key]
      (if (= (key :id) 1115500) (break))
      (tracev key)
      (if (key :ctrl)
        (case (key :utf8)
          "h" (erase-last) "c" (quit)
          "n" (inc-pos) "j" (inc-pos)
          "p" (dec-pos) "k" (dec-pos))
        (case (key :id)
          1115004 (inc-pos)
          1115002 (dec-pos)
          1115121 (set res (or (get-in sd [pos 0]) s))
          (case (key :utf8)
            "\e" (quit)
            "\t" (complete)
            (add-char (key :utf8))))))

    (while (nil? res)
      (actions (tracev (nc/get-press nc)))
      (show-ui))

    (nc/erase np))
  res)

(defn input [prmt] (choose prmt []))
