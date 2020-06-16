# Janet Fuzzy Finder

My exercise in command line programming. Think of it as fzf, but without all the
fancy stuff, but with one important addition: it prints what have been typed if
there is no remaining choice, which is great in combination with Tab key.

Even with its simplicity, it has replace wofi/dmenu utility for me.

## Installation:

You need latest development version of Janet programming language installed.
Then you can install jff with jpm package manager:

`[sudo] jpm install https://github.com/pepe/jff`.

## Usage:

`ls Code/**/* | jff` will show the choices and you can start fuzzy finding.
List of choices starts to narrow on every char. There are some special, yet
standart key combos for navigation:

- Down/Ctrl-n/Ctrl-j moves the selection down one item
- Up/Ctrl-p/Ctrl-k moves the selection up one item
- Tab replaces typed chars with the text of the selection
- Ctrl-c/Escape exits with error without printing anything
- Enter confirms the current selection and prints it to stdout

