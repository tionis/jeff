(declare-project
  :name "jff"
  :author "Josef Pospíšil <josef.pospisil@laststar.eu>"
  :description "Janet Fuzzy Finder"
  :license "MIT"
  :url "https://git.sr.ht/~pepe/jff"
  :repo "git+https://git.sr.ht/~pepe/jff"
  :dependencies ["spork"
                 "https://github.com/MorganPeterson/jermbox.git"
                 "https://github.com/crocket/janet-utf8.git"
                 "https://github.com/janet-lang/spork.git"])

(def fzy
  (declare-native
    :name "fzy"
    :source @["fzy_reduced.c" "match.c"]))

(declare-source
  :prefix "jff"
  :source ["jff/ui.janet" "jff/scorer.janet" "jff/common.janet"]
  :deps [(fzy :native)])

(declare-executable :name "jff" :entry "jff/cli.janet"
                    :install true :deps [(fzy :native)])
