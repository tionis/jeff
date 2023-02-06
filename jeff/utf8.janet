(import spork/utf8)

(defn to-codepoints [str]
  (var i 0)
  (def out @[])
  (while (< i (length str))
    (var offset 0)
    (var rune @[nil 0])
    (while (not (first rune))
      (+= offset 1)
      (set rune (utf8/decode-rune (slice str i (+ i offset)))))
    (+= i (rune 1))
    (array/push out (rune 0)))
    out)

(defn from-codepoints [arr]
  (def out @"")
  (each rune arr
    (buffer/push out (utf8/encode-rune rune)))
  out)
