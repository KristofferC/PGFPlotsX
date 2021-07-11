# [Options](@id options_header)

Options, which usually occur between brackets (`[]`) after commands like `\addplot`, `table`, or beginnings of environments like `\begin{axis}` in LaTeX code, are key to most of the functionality of PGFPlots.

```@meta
DocTestSetup = quote
    using PGFPlotsX
end
```

## The `@pgf` macro

Use the `@pgf {}` macro to define options.

```@docs
@pgf
```

For constructors that accept options, they always come *first*. When omitted, there are assumed to be no options.

```jldoctest p1
julia> c = Coordinates([1, 2, 3], [2, 4, 8]);

julia> p = @pgf PlotInc({ "very thick", "mark" => "halfcircle" }, c);

julia> print_tex(p); # print_tex can be used to preview the generated .tex
\addplot+[
    very thick,
    mark={halfcircle}
    ]
    coordinates {
        (1,2)
        (2,4)
        (3,8)
    }
    ;
```

Inside the expression following `@pgf`, `{}` expressions can be nested, and can also occur in multiple places.

```jldoctest p1
julia> @pgf a = Axis(
           {
               "axis background/.style" =
               {
                   shade,
                   top_color = "gray",
                   bottom_color = "white",
               },
               ymode = "log"
           },
           PlotInc(
           {
               smooth
           },
           c)
       );
```

which is converted to LaTeX as

```jldoctest p1
julia> print_tex(a)
\begin{axis}[
    axis background/.style={
        shade,
        top color={gray},
        bottom color={white}
        },
    ymode={log}
    ]
    \addplot+[
        smooth
        ]
        coordinates {
            (1,2)
            (2,4)
            (3,8)
        }
        ;
\end{axis}
```

!!! note

    If you use `@pgf` inside argument lists, make sure you wrap its argument in parentheses, eg
    ```julia
    Plot(@pgf({ scatter }), some_table)
    ```
    Otherwise Julia will also pass the subsequent arguments through `@pgf`, which results in an error since they are combined into a tuple.

Each option is either a standalone *keyword* (without value, modifying the plot by itself), or a *keyword-value pair*. Keywords can be entered

1. as Julia identifiers, which is useful for keywords with no spaces (eg `smooth`),

2. separated by underscores, which are replaced by spaces (eg `only_marks` will appear in LaTeX code as `only marks`),

3. or quoted as strings, eg `"very thick"`.

*Values* are provided after a `=`, `:`, or `=>`, so the following are equivalent:

1. `@pgf { draw = "black" }`,

2. `@pgf { draw : "black" }`,

3. `@pgf { draw => "black" }`.

Values should be valid Julia expressions, as they are evaluated, so you cannot use `@pgf { draw = black }` unless `black` is assigned to some Julia value in that context.

!!! note

    Keys that contain symbols that in Julia are operators (e.g the key `"axis background/.style"`) have to be entered as strings.

### Transformations

In addition to replacing underscores in keys, the following transformations of values are done when the options are written in `.tex` style:

* A list as a value is written as “comma joined” e.g. `[1, 2, 3] -> "1, 2, 3"`.

* A tuple as a value is written with braces delimiting the elements e.g. `(60, 30) -> {60}{30}`


## Modifying options after an object is created

It is sometimes convenient to set and get options after an object has been created.

You can use `getindex`, `setindex!` (ie `obj["option"]` or `obj["option"] = value`, respectively), and `delete!` just like you would for modifiable associative collections (eg a `Dict`).

```jldoctest
julia> c = Coordinates([1, 2, 3], [2, 4, 8]);

julia> p = PlotInc(c);

julia> p["fill"] = "blue";

julia> p["fill"]
"blue"

julia> @pgf p["axis background/.style"] = { shade, top_color = "gray", bottom_color = "white" };

julia> p["axis background/.style"]["top_color"];

julia> p["very thick"] = nothing # Set a value-less options;

julia> delete!(p, "fill");

julia> print_tex(p)
\addplot+[
    axis background/.style={
        shade,
        top color={gray},
        bottom color={white}
        },
    very thick
    ]
    coordinates {
        (1,2)
        (2,4)
        (3,8)
    }
    ;
```

## Working with options

Collections of options are first-class objects: they can be used independently of `Plot`, `Axis`, and similar, copied, modified, and merged.

This allows a disciplined approach to working with complex plots: for example, you can create a set of default options for some purpose (eg plots in a research paper, with a style imposed by a journal), and then modify this as needed for individual plots. It is then easy to apply, for example, a “theme” to an axis where the theme is a set of options already saved.

Another use case is creating orthogonal sets of options, eg one for axis annotations and another one for legends, and merging these as necessary.

### Extending and combining options
julia> print_tex(a)
\begin{axis}[
    xmin={0},
    ymax={1},
    ybar
    ]
\end{axis}
```

Use  `...` to splice an option into another one, e.g.

```jldoctest
julia> theme = @pgf {xmajorgrids, ymajorgrids};

julia> a = Axis(
           @pgf {theme..., title = "Foo"}
       );

julia> print_tex(a)
\begin{axis}[
    xmajorgrids,
    ymajorgrids,
    title={Foo}
    ]
\end{axis}

julia> print_tex(theme) # original is not modified
[xmajorgrids, ymajorgrids]
```

You can also `merge` sets of options:
```jldoctest
julia> O1 = @pgf { color = "red" };

julia> O2 = @pgf { dashed };

julia> O3 = @pgf { no_marks };

julia> print_tex(Plot(merge(O1, O2, O3), Table(1:2, 1:2)))
\addplot[color={red}, dashed, no marks]
    table[row sep={\\}]
    {
        \\
        1  1  \\
        2  2  \\
    }
    ;
```
Again, the value of original options is unchanged above.


### Modifying options

You can modify existing options with `push!`, `append!`, and `merge!`. The first two expect pairs of a string and a value (may be `nothing` for options like `"red"`), and are mostly useful when you are generating options using a function. `merge!` of course accepts options.

```jldoctest
julia> opt = @pgf {};

julia> push!(opt, :color => "red", :mark => "x");

julia> append!(opt, [:style => "thick", :mark_options => @pgf { scale = 0.4 }]);

julia> merge!(opt, @pgf { "error bars/y dir=both", "error bars/y explicit" });

julia> print_tex(opt)
[color={red}, mark={x}, style={thick}, mark options={scale={0.4}}, error bars/y dir=both, error bars/y explicit]
```

All containers with options also support using `merge!` directly.

```jldoctest
julia> a = Axis();

julia> @pgf opts = {xmin = 0, ymax = 1, ybar};

julia> merge!(a, opts);

julia> print_tex(a)
\begin{axis}[xmin={0}, ymax={1}, ybar]
\end{axis}
```

## Empty options

Empty options are not emitted by default, but using in LaTeX code `[]` can be useful in some cases, eg when combined with global settings `\pgfplotsset{every axis plot/.append style={...}}`. In order to force printing empty options, it is recommended to use `{}` in expressions like

```julia
@pgf Plot({}, ...)
```

## The `PGFPlotsX.Options` constructor

```@docs
PGFPlotsX.Options
```
