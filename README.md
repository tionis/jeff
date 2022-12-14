# Janet Extended Fuzzy Finder - get through some stdout almost omnisciently and friendly
> NOTE: this is a fork of https://git.sr.ht/~pepe/jff that adds a keywords based algorithm, changes the API and integrates support for shelling out to fzf

*Alpha Quality SW ahead*

My exercise in command-line programming. Think of it as fzf, but without all the
fancy stuff, but with one crucial addition: it prints what user has typed if
there is no remaining choice, which is excellent in combination with the Tab key.

Even with its simplicity, it has replaced wofi/dmenu utility for me.

## Implementation

jeff uses the algorithm used by the fzy fuzzy finder, rewritten in Janet programming
language.

Program is stable and responsive until around 1000 (depends on the machine)
when the delay starts to be perceivable. I guess it is Janet GC kicking in, as I
am not optimizing for memory consumption at all.

## Installation:

You need the latest development version of Janet programming language installed.
Then you can install jeff with the jpm package manager:

`[sudo] jpm install https://github.com/pepe/jeff`.

## Usage:

Command line arguments:

```
 Optional:
 -c, --code VALUE                            Janet function definition to transform result with. The selected choice or the PEG match if grammar provided. Default is print
 -f, --file VALUE                            Read a file rather than stdin for choices.
 -g, --grammar VALUE                         PEG grammar to match with the result. Default nil which means  no matching.
 -h, --help                                  Show this help message.
 -e, --prepare VALUE                         Janet function defition to transform each line with. Default identity.
 -p, --program VALUE                         File with code which must have three function preparer, matcher and transformer.
 -r, --prompt VALUE=>                        Change the prompt. Default: '> '.
```

`jeff < $choides` will show the choices, and you can start fuzzy finding.
List of choices starts to narrow on every char. There are some special, yet
standard key combos for navigation:

- Down/Ctrl-n/Ctrl-j moves the selection down one item
- Up/Ctrl-p/Ctrl-k moves the selection up one item
- Tab replaces typed chars with the text of the selection. To narrow the search.
- Ctrl-c/Escape exits with error without printing anything
- Enter confirms the current selection and matches/transforms/prints it to stdout

### Common

Under the ns jeff is common module with some functionality, that can be used in
in other programs for jeff. Well, for now it is only work with prefix. You can
use them easily in your programs:

```
(import jeff/common)

(def prefix (string ((os/environ) "HOME") "/Code/"))

(def prepare (common/remove-prefix prefix))

(def transform (common/prepend-prefix prefix))
```

This script will strip the prefix from all choices and prepend it back to the
result. If you save it in `/home/user/bin/jeff/code.janet` file, you can use it with:

```
#!/bin/sh

lr -1 -o A -A -t type=d  ~/Code/* ~/Code/*/* ~/Code/*/* ~/Code/*/*/* | \
  jeff -r 'sess:> ' -p ~/bin/jeff/code.janet | \
  xe swaymsg exec -- alacritty --working-directory {}
```

to open the new terminal window on selected dir.

### Examples

Run the function on the result:

```
lr -1 | janet jeff.janet -c '|(print (string/ascii-upper $))'
```

Match the result with the grammar and then runs the function:

```
lr -1 | janet jeff.janet -g '(<- (to "."))'
                        -c '|(print (string/ascii-upper (first $)))'
```

