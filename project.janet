(declare-project
  :name "jff"
  :author "Josef Pospíšil <josef.pospisil@laststar.eu>"
  :description "Janet Fuzzy Finder"
  :license "MIT"
  :url "https://git.sr.ht/~pepe/jff"
  :repo "git+https://git.sr.ht/~pepe/jff"
  :dependencies ["https://github.com/sepisoad/jtbox"
                 "https://github.com/crocket/janet-utf8.git"
                 "https://github.com/janet-lang/argparse.git"])

(declare-executable :name "jff" :entry "jff.janet" :install true)

(declare-source :source ["jff.janet" "jff/"])
