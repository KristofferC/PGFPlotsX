# Axis-like objects

## Simple group plot

```@setup pgf
using PGFPlotsX
savefigs = (figname, obj) -> begin
    pgfsave(figname * ".pdf", obj)
    run(`pdf2svg $(figname * ".pdf") $(figname * ".svg")`)
    pgfsave(figname * ".tex", obj);
    return nothing
end
```
------------------------

```@example pgf
cs = [[(0,0), (1,1), (2,2)],
      [(0,2), (1,1), (2,0)],
      [(0,2), (1,1), (2,1)],
      [(0,2), (1,1), (1,0)]]

@pgf gp = GroupPlot(
    {
        group_style = { group_size = "2 by 2",},
        height = "4cm",
        width = "4cm"
    }
)

@pgf for (i, coords) in enumerate(cs)
    push!(gp, {title = i})
    push!(gp, PlotInc(Coordinates(coords)))
end
gp
savefigs("groupplot-simple", ans) # hide
```

[\[.pdf\]](groupplot-simple.pdf), [\[generated .tex\]](groupplot-simple.tex)

![](groupplot-simple.svg)

## Multiple group plots

```@example pgf
x = linspace(0, 2*pi, 100)
@pgf GroupPlot(
    {
        group_style =
        {
            group_size="2 by 1",
            xticklabels_at="edge bottom",
            yticklabels_at="edge left"
        },
        no_markers
    },
    {},
    PlotInc(Table(x, sin.(x))),
    PlotInc(Table(x, sin.(x .+ 0.5))),
    {},
    PlotInc(Table(x, cos.(x))),
    PlotInc(Table(x, cos.(x .+ 0.5))))
savefigs("groupplot-multiple", ans) # hide
```

[\[.pdf\]](groupplot-multiple.pdf), [\[generated .tex\]](groupplot-multiple.tex)

![](groupplot-multiple.svg)


## Polar axis

```@example pgf
angles = [e/50*360*i for i in 1:500]
radius = [1/(sqrt(i)) for i in linspace(1, 10, 500)]
PolarAxis(PlotInc(Coordinates(angles, radius)))
savefigs("polar", ans) # hide
```

[\[.pdf\]](polar.pdf), [\[generated .tex\]](polar.tex)

![](polar.svg)
