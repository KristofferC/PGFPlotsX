# [`Axis` & friends](@id axislike)

```@meta
DocTestSetup = quote
    using PGFPlotsX
end
```

This section documents constructs which are similar to `Axis`. In addition to [options](@ref options_header), they accept all [axis elements](@ref axis_elements).

### Axis

```@docs
Axis
```

`Axis` make up the labels and titles etc in the figure and is the standard way of wrapping plots, represented in `TeX` as

```tex
\begin{axis} [...]
    ...
\end{axis}
```

Examples:

```jldoctest
julia> @pgf a = Axis({
              xlabel = "x",
              ylabel = "y",
              title = "Figure"
          },
          PlotInc( Expression("x^2")));

julia> print_tex(a)
\begin{axis}[
    xlabel={x},
    ylabel={y},
    title={Figure}
    ]
    \addplot+
        {x^2};
\end{axis}

julia> push!(a, PlotInc(Coordinates([1, 2], [3, 4])));


julia> print_tex(a)
\begin{axis}[
    xlabel={x},
    ylabel={y},
    title={Figure}
    ]
    \addplot+
        {x^2};
    \addplot+
        coordinates {
            (1,3)
            (2,4)
        }
        ;
\end{axis}
```

Any struct can be pushed into an `Axis`. The LaTeX code that is generated is the result of `PGFPlotsX.print_tex(io::IO, t::T, ::Axis)`, where `T` is the type of the struct.
Pushed strings are written out verbatim.

### GroupPlot

A `GroupPlot` is a way of grouping multiple plots in one figure.

```@docs
GroupPlot
```

Example:

```jldoctest
julia> @pgf gp = GroupPlot({group_style = { group_size = "2 by 1",},
                                            height = "6cm", width = "6cm"});

julia> for (expr, data) in zip(["x^2", "exp(x)"], ["data1.dat", "data2.dat"])
           push!(gp, Plot(Expression(expr)),  Plot(Table(data)))
       end;

julia> print_tex(gp)
\begin{groupplot}[
    group style={
        group size={2 by 1}
        },
    height={6cm},
    width={6cm}
    ]
    \addplot
        {x^2};
    \addplot
        table {data1.dat};
    \addplot
        {exp(x)};
    \addplot
        table {data2.dat};
\end{groupplot}
```

In order to add options to the `\nextgroupplot` call, simply add arguments in
an “option like way” (using `@pgf`) when you `push!`

```jldoctest
julia> @pgf gp = GroupPlot({group_style = { group_size = "1 by 1",}, height = "6cm", width = "6cm"});

julia> @pgf for (expr, data) in zip(["x^2"], ["data2.dat"])
           push!(gp, {title = "Data $data"}, Plot(Expression(expr)),  Plot(Table(data)))
       end;

julia> print_tex(gp)
\begin{groupplot}[
    group style={
        group size={1 by 1}
        },
    height={6cm},
    width={6cm}
    ]
    \nextgroupplot[
        title={Data data2.dat}
        ]
    \addplot
        {x^2};
    \addplot
        table {data2.dat};
\end{groupplot}
```

### PolarAxis

A `PolarAxis` plots data on a polar grid.

Example:

```jldoctest
julia> p = PolarAxis( PlotInc( Coordinates([0, 90, 180, 270], [1, 1, 1, 1])));

julia> print_tex(p)
\begin{polaraxis}
    \addplot+
        coordinates {
            (0,1)
            (90,1)
            (180,1)
            (270,1)
        }
        ;
\end{polaraxis}
```

### SmithChart

A `SmithChart` plots data on a Smith Chart axis.

Smith Charts, used commonly in RF/Microwave engineering, map the complex half
plane with positive real parts to the unit circle.

The axis will visualize plots with 2D input coordinates $z \in \mathbb{C}$ of the
form $z = x + jy \in \mathbb{C}$ with $x \ge 0$ using the map
```math
r\colon [0,\infty] \times [-\infty,\infty] \to
    \{ a+j b \;\vert\;  a^2 + b^2 = 1 \},
    \quad r(z) = \frac{z-1}{z+1}
```

Example:

```jldoctest
julia> p = SmithChart( Plot( Coordinates([(0.5,0.2),(1,0.8),(2,2)])));

julia> print_tex(p)
\begin{smithchart}
    \addplot
        coordinates {
            (0.5,0.2)
            (1,0.8)
            (2,2)
        }
        ;
\end{smithchart}
```

### Semilog and log-log axes

```@docs
SemiLogXAxis
SemiLogYAxis
LogLogAxis
TernaryAxis
```
