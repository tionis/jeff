(declare-project
  :name "jeff"
  :author "Josef Pospíšil <josef.pospisil@laststar.eu>, tionis <janet@tionis.dev>"
  :description "Janet Extended Fuzzy Finder"
  :license "MIT"
  :url "https://tasadar.net/tionis/jeff"
  :repo "git+https://tasadar.net/tionis/jeff"
  :dependencies ["spork"
                 "https://github.com/MorganPeterson/jermbox.git"])

# (declare-binscript
#   :main "bin/jeff"
#   :hardcode-syspath false
#   :is-janet true)

(declare-source
  :source ["jeff"])

(def fuzzy
  (declare-native
    :name "fuzzy"
    :source ["./cjanet/fuzzy.janet"]))

(declare-executable
  :name "jeff"
  :entry "jeff/cli.janet"
  :deps [(fuzzy :static)]
  :install true)
