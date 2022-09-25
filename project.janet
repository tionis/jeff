(declare-project
  :name "jeff"
  :author "Josef Pospíšil <josef.pospisil@laststar.eu>, tionis <janet@tionis.dev>"
  :description "Janet Extended Fuzzy Finder"
  :license "MIT"
  :url "https://tasadar.net/tionis/jeff"
  :repo "git+https://tasadar.net/tionis/jeff"
  :dependencies ["spork"
                 "https://github.com/MorganPeterson/jermbox.git"
                 "https://github.com/andrewchambers/janet-utf8.git"
                 "https://git.sr.ht/~pepe/jfzy"])

(declare-source
  :source ["jeff"])

(declare-executable :name "jeff" :entry "jeff/cli.janet"
                    :install true)
