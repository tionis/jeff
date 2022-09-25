(def- grammar ~{
  :ws (set " \t\r\n")
  :escape (* "\\" (capture 1))
  :dq-string (accumulate (* "\"" (any (+ :escape (if-not "\"" (capture 1)))) "\""))
  :sq-string (accumulate (* "'" (any (if-not "'" (capture 1))) "'"))
  :token-char (+ :escape (* (not :ws) (capture 1)))
  :token (accumulate (some :token-char))
  :value (* (any (+ :ws)) (+ :dq-string :sq-string :token) (any :ws))
  :main (any :value)
})

(def- peg (peg/compile grammar))

(defn split
  "Split a string into 'sh like' tokens, returns
   nil if unable to parse the string."
  [s]
  (peg/match peg s))

(defn- quote1
  [arg]
  (def buf (buffer/new (* (length arg) 2)))
  (buffer/push-string buf "'")
  (each c arg
    (if (= c (chr "'"))
      (buffer/push-string buf "'\\''")
      (buffer/push-byte buf c)))
  (buffer/push-string buf "'")
  (string buf))

(defn quote
  [& args]
  (string/join (map quote1 args) " "))
