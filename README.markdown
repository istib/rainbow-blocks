rainbow-blocks: Groking Lisp languages through block highlighting.
======================


Rainbow-blocks is an Emacs mode that highlights blocks made of
parentheses, brackets, and braces according to their depth. Each
successive level is highlighted in a different color. This makes it
easy to orient yourself in the code, and tell which statements are at
a given level.

It is a fork from the brilliant
[rainbow-delimiters.el](http://github.com/jlr/rainbow-delimiters) package, and
only applies minor patches.

It is inspired by Douglas Crockford's remark that highlighting scope
rather that syntax is sometimes more useful. So far, however, it does
not understand the actual scope constructs of the given language.

### Emacs Lisp example

##### rainbow delimiters
![](elisp-delims.png)
##### rainbow blocks
![](elisp-blocks.png)


### Installation

* Install via melpa:
```M-x package-install RET rainbow-blocks RET```

* Compile the file (necessary for speed):
```M-x byte-compile-file [location of rainbow-blocks.el]```

* Add the following to your dot-emacs/init file:
```(require 'rainbow-blocks)```

* Activate the mode in your init file (e.g. for clojure):
```(add-hook 'clojure-mode-hook 'rainbow-blocks-mode)```

* It is also often useful to temporarily enable the mode by just calling:
```M-x rainbow-blocks-mode ```

### Further reading

- Daniel's Lamb's [implementation for JavaScript](https://github.com/daniellmb/JavaScript-Scope-Context-Coloring)
- [Evan Brooks' article](https://medium.com/p/3a6db2743a1e/)
