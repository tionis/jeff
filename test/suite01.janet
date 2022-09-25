(use spork/test)
(import ../jeff/shlex)

(start-suite 0)

(assert (deep= 
          (shlex/split ` "c d \" f" ' y z'  a b a\ b --cflags `)
          @["c d \" f" " y z" "a" "b" "a b" "--cflags"]))

(end-suite)
