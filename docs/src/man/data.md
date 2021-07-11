# Data

```@meta
DocTestSetup = quote
    using PGFPlotsX
end
```

There are multiple ways of representing data in PGFPlots.

## [Table and TableData](@id table_header)

A `Table` represents a matrix of data where each column is labeled. It can simply point to an external data file or store the data inline in the `tex` file. `Table`s can have options.

`TableData` is the representation of *just the data*, without the `table[options]` part. It is useful for inline tables in specials cases. Also, calls to `Table` use `TableData` to convert the arguments, so if you want to learn about all the ways to construct a `Table`, see the methods of [`TableData`](@ref).

```@docs
Table
TableData
```

Examples:

```julia-repl make_into_doctest
julia> t = @pgf Table({x = "Dof"}, "data.dat");

julia> print_tex(t)
table [x={Dof}] {
    <ABSPATH>/data.dat
}
```

Inline data is constructed using a keyword constructor:

```jldoctest
julia> t = @pgf Table({x => "Dof", y => "Err"},
                      [:Dof => [1, 2, 4], :Err => [2.0, 1.0, 0.1]]);

julia> print_tex(t)
table[
    row sep={\\},
    x={Dof},
    y={Err}
    ]
{
    Dof  Err  \\
    1.0  2.0  \\
    2.0  1.0  \\
    4.0  0.1  \\
}
```

You can give a type that supports the [`Tables.jl`](https://juliadata.github.io/Tables.jl/stable/) as the second
argument to `Table` and the data and column names will be inferred.
For example, if you load the DataFrames package, you can create tables from data frames, see the examples in [Julia types](@ref).

!!! note

    By default, PGFPlots expects rows to be separated in a table with a newline. This can be “fragile” in LaTeX, in the sense that linebreaks may be merged with other whitespace within certain constructs, eg macros. In order to prevent this, this package uses the option `rowsep=\\` by default. This is taken care of automatically, except for inline tables where you have to specify it manually. See the `patch` plot in the [gallery](@ref manual_gallery).

## [Using coordinates](@id coordinates_header)

Coordinates are a list of points `(x,y)` or `(x,y,z)`. PGFPlotsX wraps these in the [`Coordinate`](@ref) type, but for multiple coordinates, it is recommended that you use the `Coordinates` constructor, which has convenience features like converting non-finite numbers to skipped points (represented by `nothing`).

Strings are also accepted in place of numbers, and can be used for *symbolic* coordinates (eg for categorical data). See [this example](@ref symbolic_coordinates_example).

### `Coordinates`

* `Coordinates(x, y, [z])` where `x` and `y` (and optionally `z`) are lists.

* `Coordinates(points)` where `points` is a list of tuples, [`Coordinate`](@ref)s, or `nothing`, e.g. `x = [(1.0, 2.0), (2.0, 4.0)]`.

Errors can be added to `Coordinates` with keywords.

```@docs
Coordinates
```

Examples:

```jldoctest
julia> x = [1, 2, 3]; y = [2, 4, 8]; z = [-1, -2, -3];

julia> print_tex(Coordinates(x, y))
coordinates {
    (1,2)
    (2,4)
    (3,8)
}

julia> print_tex(Coordinates(x, y, z))
coordinates {
    (1,2,-1)
    (2,4,-2)
    (3,8,-3)
}

julia> print_tex(Coordinates(x, x.^3))
coordinates {
    (1,1)
    (2,8)
    (3,27)
}

julia> print_tex(Coordinates([(1.0, 2.0), (2.0, 4.0)]))
coordinates {
    (1.0,2.0)
    (2.0,4.0)
}

julia> c = Coordinates(x, y, xerror = [0.2, 0.3, 0.5], yerror = [0.2, 0.1, 0.5]);

julia> print_tex(c)
coordinates {
    (1,2) +- (0.2,0.2)
    (2,4) +- (0.3,0.1)
    (3,8) +- (0.5,0.5)
}
```

### Individual coordinates

Use this constructor when you need just a single `Coordinate`, eg as in

```julia
@pgf Axis(
    {
        legend_style =
        {
            at = PGFPlotsX.Coordinate(0.5, -0.15),
            anchor = "north",
            legend_columns = -1
        },
    }, ...)
```

```@docs
Coordinate
```

## Expression

```@docs
Expression
```

Example:

```jldoctest
julia> ex = Expression("exp(-x^2)");

julia> print_tex(ex)
{exp(-x^2)}
```

## Graphics

```@docs
Graphics
```

Example:

```jldoctest
julia> print_tex(Graphics("img.png"))
graphics {img.png}
```

## Strings in `Plot`

Strings (technically, all subtypes of `AbstractString`) are also accepted by plots, and will be emitted into LaTeX *as is*. This is mostly useful for using constructs from TikZ that do not have a native representation in this package direcly as LaTeX code. See [this example](@ref latex-plot-elements).
