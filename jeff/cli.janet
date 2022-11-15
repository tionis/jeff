(use spork/argparse)

(use ./ui)


(def argparse-params
  ["Janet Fuzzy Finder - get through some stdout almost omnisciently 
and friendly."
   "file" {:kind :option
           :short "f"
           :help "Read a file rather than stdin for choices."}
   "prompt" {:kind :option
             :short "r"
             :help "Change the prompt. Default: '> '."
             :default "> "}
   "prepare" {:kind :option
              :short "e"
              :help "Janet function defition to transform each line with. 
Default identity."}
   "grammar" {:kind :option
              :short "g"
              :help "PEG grammar to match with the result. Default nil which 
means no matching."}
   "code" {:kind :option
           :short "c"
           :help "Janet function definition to transform result with. 
The selected choice or the PEG match if grammar provided. Default is print."}
   "program" {:kind :option
              :short "p"
              :help "File with code which must have three values: prepare 
function, grammar peg and transform function."}
   "keywords" {:kind :flag
               :short "k"
               :help "Instead of matching spaces literally, split the search 
string at spaces and search for each part individually."}])

(defn main [_ &]
  (if-let [parsed (argparse ;argparse-params)]
    (let [{"file" file
           "prompt" prmt
           "prepare" prepare
           "grammar" grammar
           "code" code
           "program" program
           "keywords" keywords?} parsed]

      (var preparer identity)
      (var matcher identity)
      (var transformer print)

      (if grammar (set matcher |(peg/match (parse grammar) $)))
      (if code (set transformer (eval (parse code))))
      (if prepare (set preparer (eval (parse prepare))))

      (when-let [program (and program (dofile program))]
        (if-let [prepare-fn (get-in program ['prepare :value])]
          (set preparer prepare-fn))
        (if-let [grammar-def (get-in program ['grammar :value])]
          (set matcher |(peg/match grammar-def $)))
        (if-let [transform-fn (get-in program ['transform :value])]
          (set transformer transform-fn)))
      (def file (if file (file/open file :r) stdin))
      (->> (seq [l :iterate (:read file :line)] (preparer (string/trim l)))
           (filter |(not (empty? $)))
           (|(choose $0 :keywords? keywords? :prmpt prmt))
           (matcher)
           (transformer)))))
