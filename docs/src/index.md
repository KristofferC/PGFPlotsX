# PGFPlotsX

## Introduction

*PGFPlotsX* is a Julia package for creating publication quality figures using the LaTeX library [PGFPlots](http://pgfplots.sourceforge.net/)
as the backend. PGFPlots has [extensive documentation (pdf)](http://pgfplots.sourceforge.net/pgfplots.pdf)
and a rich database of answered questions on places like [stack overflow](https://stackoverflow.com/questions/tagged/pgf)
and [tex.stackexchange](https://tex.stackexchange.com/questions/tagged/pgfplots).
In order to take advantage of this, the syntax in PGFPlotsX is similar to the one written in `.tex`.
It is therefore, usually, easy to translate a PGFPlots example written in `.tex` to PGFPlotsX Julia code.
The advantage of using *PGFPlotsX.jl* over writing raw latex code is that it is possible to use Julia objects directly in the figures. Furthermore, the figures can be previewed in notebooks and IDE's, like julia-vscode and Atom-Juno.
It is for example possible to directly use a `DataFrame` from [*DataFrames.jl*](https://github.com/JuliaData/DataFrames.jl) as a PGFPlots `table`.

## Installation

```julia-repl
Pkg.add("PGFPlotsX")
```

*PGFPlots.jl* requires a latex installation with the PGFPlots package installed.
We recommend using a latex installation with access to lualatex since it can have significantly better performance than pdflatex.

To generate or preview figures in svg (like is done by default in Jupyter notebooks) `pdf2svg` is required. This can obtained by, on Ubuntu, running `sudo apt-get install pdf2svg`, on RHEL/Fedora `sudo dnf install pdf2svg` and on macOS e.g. `brew install pdf2svg`. On Windows, the binary can be downloaded from [here](http://www.cityinthesky.co.uk/opensource/pdf2svg/); be sure to add `pdf2svg` to the `PATH`.

For png figures `pdftoppm` is required. This should by default on Linux and on macOS should be available after running `brew install poppler`. It is also available in the *Xpdf tools* archive which can be downloaded [here](http://www.foolabs.com/xpdf/download.html).

!!! note
    If you installed a new latex engine, `pdf2svg` or `pdftoppm` after you installed *PGFPlotsX* you need to run `Pkg.build("PGFPlotsX")` for this to be reflected. The output from `Pkg.build` should tell you what latex engines and figure converters it finds.
