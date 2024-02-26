# lproof Extension for Quarto

This extension provides support for HTML and LaTeX rendering of object-language proofs (lproofs) in
quarto markdown.

## Installation

```sh
quarto add https://github.com/anubav/lproof/archive/refs/heads/main.zip
```

The above command will install the extension under the `_extensions` subdirectory of your quarto
document or project.

### Usage

Object Language proofs are delimited within a fenced
[div](https://quarto.org/docs/authoring/markdown-basics.html#divs-and-spans) block with the custom
class `.olproof`. Every line of text in the block should be indented (at least) four spaces (or one
tab) so as to ensure that quarto reads the text verbatim. This ensures that special characters do not trigger special formatting,
and all spaces and line breaks are preserved.

At its most basic, an lproof is simply a sequence of numbered lines (formatted like a markdown ordered list), each of which
contains text corresponding to the content of that line of the proof followed by an optional justification
for that line given by text enclosed within square brackets (`[` and `]`).

For example, the following text describes a simple lproof:

```
::: {.olproof} :::

    1. $P$                  [Premise]
    2. $P\rightarrow Q$     [Premise]
    3. $Q$                  [Modus Ponens: 1, 2]

:::
```

Written
