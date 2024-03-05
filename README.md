# lproof Extension for Quarto

This extension provides support for HTML and LaTeX rendering of object-language proofs (lproofs) in
quarto markdown.

## Installation

The following command will install the extension under the `_extensions` subdirectory of your quarto
project:

```sh
quarto add https://github.com/anubav/lproof/archive/refs/heads/main.zip
```

To enable the extension in your quarto project, add `lproof` to the list of filters in your
`\_quarto.yml` file or document front matter.

```
---
title: Quarto Document
filters:
   - lproof
   ...
---
```

## Basic Usage

Object-language proofs (lproofs) are delimited within a fenced
[div](https://quarto.org/docs/authoring/markdown-basics.html#divs-and-spans) block assigned the custom
class `.lproof`. Every line of text in the block must be indented (at least) four spaces (or one
tab) so as to ensure that quarto reads the text
[verbatim](https://pandoc.org/chunkedhtml-demo/8.5-verbatim-code-blocks.html). Apart from this
requirement any space between elements is ignored and should be utilized to improve readability.

### Sequential Proofs

The most basic lproof is simply a sequence of numbered lines (formatted like a markdown [ordered list](https://quarto.org/docs/authoring/markdown-basics.html#lists)), each of which
contains the formula appearing on that line of the proof followed by an optional justification
for that line enclosed within square brackets (`[` and `]`):

```
::: {.lproof} :::

    1. P                  [Premise]
    2. P\rightarrow Q     [Premise]
    3. Q                  [Modus Ponens: 1, 2]

:::
```

All formulas are automatically formatted in math-mode.
When written to HTML this proof is rendered as follows:

![simple_lproof](images/simple.jpeg)

### Fitch-Style Proofs

The lproof extension also allows for the formatting of Fitch-style proofs. Repeated vertical line symbols (`|`) are used to indicate
the depth of the subproof in which a line occurs and underscores (`_`) are used to mark new hypotheses
initiating subproofs.

```
::: {.lproof} :::

    1.  |_ p\rightarrow q                                                           [Hypothesis]
    2.  | |_ q\rightarrow r                                                         [Hypothesis]
    3.  | | |_ p                                                                    [Hypothesis]
    4.  | | |  p\rightarrow q                                                       [Reiteration: 1]
    5.  | | |  q                                                                    [Modus Ponens: 3, 4]
    6.  | | |  q\rightarrow r                                                       [Reiteration: 2]
    7.  | | |  r                                                                    [Modus Ponens: 5, 6]
    8.  | |  p\rightarrow r                                                         [$\rightarrow\text{I}$: 3--7]
    9.  |  (q\rightarrow r)\rightarrow(p\rightarrow r)                              [$\rightarrow\text{I}$: 2--8]
    10. |  (p\rightarrow q)\rightarrow((q\rightarrow r)\rightarrow(p\rightarrow r)) [$\rightarrow\text{I}$: 1--9]

:::
```

This Fitch-style proof is rendered as follows:

![fitch lproof](images/fitch.jpeg)

### Gentzen-style Proof Trees [TODO]

## Additional Formatting

### Line Numbers

Line numbers are represented by strings to be rendered in math-mode. Thus, any arbitrary math
expression can be used to denote a line number, e.g.:

```
::: {.lproof} :::

    n.   P                  [Premise]
    n+1. P\rightarrow Q     [Premise]
    n+2. Q                  [Modus Ponens: n, n+1]

:::
```

![simple_lproof_with_indexes](images/simple_2.jpeg)

### Justifications and Line References

Each line in an lproof may be given an optional justification, enclosed within square brackets. Justifications
have two parts: (1) an explanation describing what justifies the inclusion of that line in the
proof; and (2) an optional list of references to previous lines in the proof. The explanation is
separated from the reference list by a colon `:`. Explanations are not rendered in math-mode, so
math content must be enclosed in dollar signs `$...$`. Reference lists are given by a comma-separated
list of either
individual line numbers, or line number ranges, the endpoints of which are separated by two hyphens
`--`. The following are admissible justifications:

`[Explanation]`

`[Explanation: 1, 2, 3]`

`[Explanation: 1, n--n+2, n+5]`

In the HTML rendering of the proof, clicking on a line highlights all other
lines referenced in its justification. In order for cross-references to work, the same string must
be used for both the line number and
the reference to that line.

### Ellipses

Ellipses `...` may be used in an lproof to indicate an implied interpolation. For example:

```
::: {.lproof} :::

    1. P                  [Premise]
    2. P\rightarrow Q     [Premise]
        ...
    n. Q                  [Modus Ponens: 1, 2]

:::
```

![simple_lproof_ellipses](images/ellipses.jpeg)

### Key Substitutions [TODO]

## Customization

### CSS Styling of lproofs [TODO]
