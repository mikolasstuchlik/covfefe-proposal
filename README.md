# DSL proposal discussion for Covfefe

## Aim
As described in [original issue](https://github.com/palle-k/Covfefe/issues/4), I struggled to adapt grammar of Relax NG Compact as documented in https://www.oasis-open.org/committees/relax-ng/compact-20020607.html to the Covfefe grammar representation.

Some sort of compile time verification would solve a lot of issues.

Since this is a proposal intended for further dicussion I've taken the liberty to adapt some of the notation to the notation I've learned at school. I was not able to mimic the exact notation because of Swift's limitations.

For the purposes of this proposal, I've copied origian grammar documentation from https://github.com/palle-k/Covfefe/blob/master/BNF.md and added documentation of the proposed DSL.

I look forward to your suggestions and feedback.

---

# BNF

Covfefe allows context free grammars to be specified using a language that is a superset of BNF.

## Contents

1. [Productions](#productions)
2. [Terminals](#terminals)
3. [Alternations](#alternations)
3. [Sequence Grouping](#sequence-grouping)
4. [Optional Sequences](#optional-sequences)
5. [Sequence Repetitions](#sequence-repetitions)
6. [Character Ranges](#character-ranges)
7. [Full Grammar](#full-grammar)

## Productions

A production in a context free grammar has the form `X -> b`, which indicates that `X` can be replaced by `b`.
`X` is a non-terminal, `b` is a string of terminals and non-terminals.

In BNF, a non-terminal is written as `<A>`, a terminal is written as `'a'` or `"a"`.
An assignment is written as `lhs ::= rhs`.

A grammar that produces `Hello World` can thereby be expressed as

```
<S> ::= 'hello' <whitespace> 'world'
<whitespace> ::= ' '
<whitespace> ::= '\t'
```

> ### Production
> Production in the DSL is represented by type `Production` which is in the DSL instantiated using infix operator `→` which takes argument of `NonTerminal` type and `Product`, for example `<NonTerminal> → <Product>` Product is a protocol which represents anything, that is valid right side of a production expression. Notice, that if more than one production occurs for a given non-terminal, productions are combined into one alternation.
>
>### Non-Terminal
>Non-terminal is represented by type `NonTerminal`. NonTerminal may be instantiated by using prefix operator `%` followed by string indetifyin the non-terminal. Example `%"my-non-terminal"`.

## Terminals

Terminals are strings of characters that are delimited either by `'`s or `"`s. 

### Escaping

To express characters such as newlines, tabs and unicode symbols, backslashes can be used:

```
<S> ::= '\n' | '\t' | '\\' | '\u{1F602}'
```

This grammar produces a single newline, a single tab, a single `\` or a single `😂`.

#### Warning

When adding grammars as strings in Swift code, backslashes need to be escaped.

The above grammar then becomes:

```swift
let grammarString = "<S> ::= '\\n' | '\\t' | '\\\\' | '\\u{1F602}'"
```
>### Terminal
>Terminal is represented by type `Terminal`. Terminal may be instantiated by using prefix operator `^` followed by string which represents the terminal in the grammar. Example `^"terminal"` or `^""` which is equivalent to `ε`. 
>*Note: I wonder whether introducing a static instance of terminal `let ε = ^""` would have a positive impact on the DSL and whether Optional sequence should be removed since it can be replaced by Alternation of any given set of products with `ε`.* 


## Alternations

In the above example, whitespace can be replaced either by `' '` or by `'\t'`.
This can be written as

```
<whitespace> ::= ' ' | '\t'
```

>### Alternation
>Alternation is represented by `OptionProduct` type. Alternation may be instantiated with infix operator `|` from two instances of Product. Example: `%"non-terminal" → ^"aTerminal" | ^"anotherTerminal"`.

Concatenation has a higher precedence than alternations, so the following grammar produces `ab` and `cd`

```
<S> ::= 'a' 'b' | 'c' 'd'
```

>### Concation
>Concation is represented by `StringProduct` type. Concation may be instantiated with infix operator `..` from two instances of Product. Unfortunately `.` operator is not available. Example: `%"non-terminal" → ^"aTerminal" .. %"another-non-terminal"`.

## Sequence Grouping

Parentheses (`(` and `)`) can be used to group symbols together.

The following grammar produces `abd` and `acd`:

```
<S> ::= 'a' ('b' | 'c') 'd'
```

> As for now, there is no explicit support for Sequence Grouping. Implicitly, each `OptionProduct` is lowered with parentheses.

## Optional Sequences

To mark a sequence as optional, brackets (`[` and `]`) can be used.

The following grammar produces `abc` and `ac`:

```
<S> ::= 'a' ['b'] 'c'
```

>### Optional Sequences
>Optional Sequence is represented by `OptionalProduct` type. Optional Sequences may be instantiated using postfix operator  `-?` using any instance of Product. Unfortunately `?` operator is not available. Example: `%"non-terminal" → (^"aTerminal")-?`.

## Sequence Repetitions

To repeat a sequence, braces (`{` and `}`) can be used.

The following grammar produces `aba`, `abba`, `abbba`, etc. but not `aa`:

```
<S> ::= 'a' {'b'} 'a'
```

>### Sequence Repetition - Positive iteration
>Positive iteration is represented by `PositiveIterationProduct` type. Positive iteration may be instantiated using postfix operator  `+` using any instance of Product. Example: `%"non-terminal" → (^"aTerminal")+`.

To also generate `aa`, repetitions can be matched with optional sequences:

```
<S> ::= 'a' [{'b'}] 'a'
```

>### Sequence Repetition - Iteration
>Iteration is represented by `IterationProduct` type. Iteration may be instantiated using postfix operator  `*` using any instance of Product. Example: `%"non-terminal" → (^"aTerminal")*`.

It is preferred to make the entire repetition optional instead of repeating an optional sequence.

The repetition is generated using a left-recursive auxiliary rule.

## Character Ranges

To make it easier to specify grammars that recognize a large alphabet, character ranges can be used.
The following grammar recognizes all upper and lower case roman letters:

```
<S> ::= 'A' ... 'Z' | 'a' ... 'z'
```

The lower bound of a character range must be less than or equal the upper bound (e.g. `'b' ... 'a'` is an invalid range).
The bounds of a range must be exactly one character. The characters can consist of multiple unicode scalars.

>Character ranges are not currently implemented.

## Full Grammar

The grammar that is recognized is the following:

```ebnf
(* Production rules are separated by newlines and optional whitespace *)
syntax = optional-whitespace | newlines | rule | rule, newlines | syntax, newlines, rule, newlines | syntax, newlines, rule;

(* A rule consists of a non-terminal pattern name, an assignment operator and a production expression *)
rule = optional-whitespace, rule-name-container, optional-whitespace, assignment-operator, optional-whitespace, expression, optional-whitespace;

(* Rule names are strings of alphanumeric characters *)
rule-name-container = "<", rule-name, ">";
rule-name = rule-name, rule-name-char | "";
rule-name-char = "[a-zA-Z0-9-_]";

assignment-operator = ":", ":", "=";

(* An expression can either be a concatenation or an alternation *)
expression = concatenation | alternation;

(* An alternation is a sequence of one or more concatenations separated by | *)
alternation = expression, optional-whitespace, "|", optional-whitespace, concatenation;

(* A concatenation is a string of terminals and non-terminals *)
concatenation = expression-element | concatenation, optional-whitespace, expression-element;

(* An atom of a expression can either be a terminal literal, a non-terminal or a group *)
expression-element = literal | rule-name-container | expression-group | expression-repetition | expression-optional;

(* Expression containers *)
expression-group = "(", optional-whitespace, expression, optional-whitespace, ")";
expression-optional = "[", optional-whitespace, expression, optional-whitespace, "]";
expression-repetition = "{", optional-whitespace, expression, optional-whitespace, "}";

(* Terminal literals *)
literal = "'", string-1, "'" | '"', string-2, '"' | range-literal;
range-literal = single-char-literal, optional-whitespace, ".", ".", ".", optional-whitespace, single-char-literal;

(* Strings and characters *)
string-1 = string-1, string-1-char | "";
string-1-char = ? any character except '"' ? | string-escaped-char | escaped-single-quote;
string-2 = string-2, string-2-char | "";
string-2-char = ? any character except "'" ? | string-escaped-char | escaped-double-quote;

single-char-literal = "'", string-1-char, "'" | '"', string-2-char, '"';

(* Escape sequences *)
string-escaped-char = unicode-scalar | carriage-return | line-feed | tab-char | backslash;

backslash = "\\", "\\";
line-feed = "\\", "n";
carriage-return = "\\", "r";
tab-char = "\\", "t";

escaped-double-quote = "\\", '"';
escaped-single-quote = "\\", "'";

unicode-scalar = "\\", "u", "{", unicode-scalar-digits, "}";
unicode-scalar-digits = [digit], [digit], [digit], [digit], [digit], [digit], [digit], digit;
digit = '0' ... '9' | 'A' ... 'F' | 'a' ... 'f';

(* Whitespace *)
newlines = "\n" | "\n", optional-whitespace, newlines;

optional-whitespace = "" | whitespace, optional-whitespace;
whitespace = " " | "\t" | "\n" | comment;

(* Comments *)
comment = "(", "*", comment-content, "*", ")" | "(", "*", "*", "*", ")";
comment-asterisk = comment-asterisk, "*" | "*";
comment-content = comment-content, comment-content-char | "";
comment-content-char = "[^*(]" | comment-asterisk, "[^)]" | comment-open-parenthesis, "[^*]" | comment;
comment-open-parenthesis = comment-open-parenthesis, "(" | "(";
```
