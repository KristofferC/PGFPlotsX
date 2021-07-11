# [Axis elements](@id axis_elements)

```@meta
DocTestSetup = quote
    using PGFPlotsX
end
```

The following types are accepted as elements of [`Axis` & friends](@ref axislike):

- plot variants: [`Plot`](@ref), [`PlotInc`](@ref), [`Plot3`](@ref), [`Plot3Inc`](@ref),

- legend specifications: [`Legend`](@ref), [`LegendEntry`](@ref),

- [strings](@ref latex_code_strings), which are inserted verbatim.

This section documents these.

## [Plots](@id plotlike)

A plot is an element inside an axis. It can be a wide range of constructs, from a simple line to a 3D surface. A plot is created by wrapping one of the [data structures](@ref Data).

!!! note

    PGFPlots uses `\addplot` & friends for visualization that uses a single data source, in most cases drawn using the same style. If you want to plot multiple sources of data that share axes, eg two time series, your axis will have multiple “plots” in the terminology of PGFPlots.

### Plot and PlotInc

For `\addplot` and `\addplot+`, respectively.

```@docs
Plot
PlotInc
```

Example:

```jldoctest
julia> p = @pgf PlotInc({ blue }, Table("plotdata/invcum.dat"));

julia> print_tex(p)
\addplot+[
    blue
    ]
    table {plotdata/invcum.dat};
```

### Plot3

`Plot3` will use the `\addplot3` command instead of `\addplot` to draw 3D graphics.
Otherwise it works the same as `Plot`. The incremental variant is `Plot3Inc`.

```@docs
Plot3
Plot3Inc
```

Example:

```jldoctest
julia> x, y, z = [1, 2, 3], [2, 4, 8], [3, 9, 27];

julia> p = @pgf Plot3({ very_thick }, Coordinates(x, y, z));

julia> print_tex(p)
\addplot3[
    very thick
    ]
    coordinates {
        (1,2,3)
        (2,4,9)
        (3,8,27)
    }
    ;
```

## Legends

```@docs
Legend
LegendEntry
```

A [`Legend`](@ref) can be used to add legends to an axis, for multiple plots at the same time. In contrast, [`LegendEntry`](@ref) applies to the preceding plot.

Example:

```jldoctest
julia> print_tex(Legend(["Plot A", "Plot B"]))
\legend{{Plot A},{Plot B}}
```

## Horizontal and vertical lines

[`HLine`](@ref) and [`VLine`](@ref) have no equivalent constructs in `pgfplots`, they are provided for convenient drawing of horizontal and vertical lines. When options are used, they are passed to the TikZ function `\draw[...]`.

```@docs
HLine
VLine
```

## [Using LaTeX code directly](@id latex_code_strings)

In case there is no type defined in this package for some construct, you can use a `String` in an axis, and it is inserted verbatim into the generated LaTeX code. [Raw string literals](https://docs.julialang.org/en/latest/manual/strings/#man-raw-string-literals-1) and the package [LaTeXStrings](https://github.com/stevengj/LaTeXStrings.jl) are useful to avoid a lot of escaping.

[The gallery](@ref latex-code) has some detailed examples, eg for annotating plots.
