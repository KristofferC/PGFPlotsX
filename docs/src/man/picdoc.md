# TikzPicture

```@meta
DocTestSetup = quote
    using PGFPlotsX
end
```

A `TikzPicture` can contain multiple `Axis`-like objects.

```@docs
TikzPicture
```

Example:

```jldoctest
julia> tp = @pgf TikzPicture({ "scale" => 1.5 }, Axis(Plot(Coordinates([1, 2], [2, 4]))));

julia> print_tex(tp)
\begin{tikzpicture}[
    scale={1.5}
    ]
\begin{axis}
    \addplot
        coordinates {
            (1,2)
            (2,4)
        }
        ;
\end{axis}
\end{tikzpicture}
```

# TikzDocument

A `TikzDocument` is the highest level object and represents a whole `tex` file.
It includes a list of objects between `\begin{document}` and `\end{document}`.

```@docs
TikzDocument
```

A very simple example where we simply create a `TikzDocument` with a string is shown below.
Normally you would also push `Axis`-like objects that contain plots.

```julia-repl
julia> td = TikzDocument();

julia> push!(td, "Hello World");

julia> print_tex(td)
\RequirePackage{luatex85}
\documentclass[tikz]{standalone}
% Default preamble
\usepackage{pgfplots}
\pgfplotsset{compat=newest}
\usepgfplotslibrary{groupplots}
\usepgfplotslibrary{polar}
\usepgfplotslibrary{statistics}
\begin{document}
Hello World
\end{document}
```

A `TikzDocument` uses [global variables](@ref customizing_the_preamble) to construct a preamble, and allows the user to add extra lines to this (eg in case you want to add `\usepackage` lines), or disable it altogether.

!!! note

    There is usually no need to explicitly create a `TikzDocument` or `TikzPicture`.
    Only do this if you want to give special options to them. It is possible to show or save
    an `Axis` or e.g. a `Plot` directly, and they will then be wrapped in the default "higher level" objects.
