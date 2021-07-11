@testset "printing Julia types to TeX" begin
    @test squashed_repr_tex("something") == "something"
    @test squashed_repr_tex(4) == "4"
    @test squashed_repr_tex(NaN) == "nan"
    @test squashed_repr_tex(Inf) == "+inf"
    @test squashed_repr_tex(-Inf) == "-inf"
    @test squashed_repr_tex(missing) == "nan"
    @test squashed_repr_tex(Date(2000, 1, 2)) == "2000-01-02"
    @test squashed_repr_tex(DateTime(2000, 1, 2, 3, 4)) == "2000-01-02 03:04"
end

@testset "coordinate" begin
    # invalid coordinates
    @test_throws ArgumentError PGFPlotsX.Coordinate((1, ))    # dimension not 2 or 3
    @test_throws ArgumentError PGFPlotsX.Coordinate((1, 2);   # can't specify both
                                              error = (0, 0), errorplus = (0, 0))
    @test_throws MethodError Coordinates((1, 2); error = (3, )) # incompatible dims

    # valid forms
    @test squashed_repr_tex(PGFPlotsX.Coordinate((1, 2))) == "(1,2)" # NOTE important not to have whitespace
    @test squashed_repr_tex(PGFPlotsX.Coordinate((1, 2); error = (3, 4))) == "(1,2) +- (3,4)"
    @test squashed_repr_tex(PGFPlotsX.Coordinate((1, 2); errorminus = (3, 4))) ==
        "(1,2) -= (3,4)"
    @test squashed_repr_tex(PGFPlotsX.Coordinate((1, 2);
                                           errorminus = (3, 4),
                                           errorplus = (5, 6))) ==
                                               "(1,2) += (5,6) -= (3,4)"
    @test squashed_repr_tex(PGFPlotsX.Coordinate((1, 2); meta = "blue")) == "(1,2) [blue]"
    @test squashed_repr_tex(PGFPlotsX.Coordinate((NaN, 1))) == "(NaN,1)"
    @test squashed_repr_tex(PGFPlotsX.Coordinate(("a fish", 1))) == "(a fish,1)"

    # convenience constructors
    @test Coordinate(1, 2) == Coordinate((1, 2))
    @test Coordinate(1, 2, 3) == Coordinate((1, 2, 3))
end

@testset "coordinates and convenience constructors" begin
    @test_throws ArgumentError Coordinates([(1, 2), (1, 2, 3)]) # incompatible dims
    @test_throws ArgumentError Coordinates([(1, 2), "invalid"]) # invalid value

    # from Vectors and AbstractVectors
    @test Coordinates([1, 2], [3.0, 4.0]).data == PGFPlotsX.Coordinate.([(1, 3.0), (2, 4.0)])
    @test Coordinates(1:2, 3:4).data == PGFPlotsX.Coordinate.([(1, 3), (2, 4)])
    # skip empty
    @test Coordinates([(2, 3), (), nothing]).data ==
        [PGFPlotsX.Coordinate((2, 3)), nothing, nothing]
    @test Coordinates(1:2, 3:4, (1:2)./((3:4)')).data ==
        Coordinates(Any[1, 2, NaN, 1, 2, NaN],
                    Any[3, 3, NaN, 4, 4, NaN],
                    Any[1/3, 2/3, NaN, 1/4, 2/4, NaN]).data
    # from iterables
    @test Coordinates(enumerate(3:4)).data == PGFPlotsX.Coordinate.([(1, 3), (2, 4)])
    @test Coordinates((x, 1/x) for x in -1:1).data ==
        [PGFPlotsX.Coordinate((-1, -1.0)), nothing, PGFPlotsX.Coordinate((1, 1.0))]
    let x = 1:3,
        y = -1:1,
        z = x ./ y
        @test Coordinates(x, y, z).data ==
            Coordinates((x, y, x / y) for (x,y) in zip(x, y)).data
    end
    # from Measurements
    let x = [1.0 ± 0.1, 2.0 ± 0.2]
        y = [3.0 ± 0.3, 4.0 ± 0.4]
        @test Coordinates(x, y).data ==
            Coordinates([1.0, 2.0], [3.0, 4.0], xerror = [0.1, 0.2], yerror = [0.3, 0.4]).data
        @test Coordinates(x, [3.0, 4.0]).data ==
            Coordinates([1.0, 2.0], [3.0, 4.0], xerror = [0.1, 0.2]).data
        @test Coordinates([1.0, 2.0], y).data ==
            Coordinates([1.0, 2.0], [3.0, 4.0], yerror = [0.3, 0.4]).data
    end

    # meta printing
    @test squashed_repr_tex(Coordinates([1], [1]; meta = [RGB(0.1, 0.2, 0.3)])) ==
        "coordinates {\n(1,1) [rgb=0.1,0.2,0.3]\n}"
end

@testset "tables" begin
    # compare results to these using ≅, defined above
    table_named_noopt = Table(hcat(1:10, 11:20); colnames=["a", "b"], scanlines=Int[])
    table_unnamed_noopt = Table(hcat(1:10, 11:20); colnames=nothing, scanlines=Int[])
    opt = @pgf { meaningless = "option" }
    table_named_opt = Table(opt, hcat(1:10, 11:20); colnames=["a", "b"], scanlines=Int[])

    # named columns, without options
    @test Table(:a => 1:10, :b => 11:20) ≅ table_named_noopt
    @test Table(; a = 1:10, b = 11:20) ≅ table_named_noopt
    @test Table([:a => 1:10, :b => 11:20]) ≅ table_named_noopt
    @test Table(hcat(1:10, 11:20); colnames = [:a, :b]) ≅ table_named_noopt

    # named columns, with options
    @test Table(opt, :a => 1:10, :b => 11:20) ≅ table_named_opt
    @test Table(opt, [:a => 1:10, :b => 11:20]) ≅ table_named_opt
    @test Table(opt, hcat(1:10, 11:20); colnames = [:a, :b]) ≅ table_named_opt

    # unnamed columns, without options
    @test Table(1:10, 11:20) ≅ table_unnamed_noopt
    @test Table([1:10, 11:20]) ≅ table_unnamed_noopt
    @test Table(hcat(1:10, 11:20)) ≅ table_unnamed_noopt

    # matrix and edges
    let x = randn(10), y = randn(5), z = cos.(x .+ y')
        @test Table(x, y, z) ≅ Table(PGFPlotsX.Options(),
                                             hcat(PGFPlotsX.matrix_xyz(x, y, z)...);
                                             colnames=["x", "y", "z"], scanlines=10)
    end

    # dataframe
    @test Table(DataFrame(a = 1:5, b = 6:10)) ≅
        Table(PGFPlotsX.Options(), hcat(1:5, 6:10), colnames=["a", "b"], scanlines=0)

    # can't determine if it is named or unnamed
    @test_throws ArgumentError Table([1:10, :a => 11:20])

    @test squashed_repr_tex(Table(PGFPlotsX.Options(),
                                      [1 NaN;
                                       -Inf 4.0],
                                      ["xx", "yy"],
                                      [1])) == "table[\nrow sep={\\\\}\n]\n{\nxx yy \\\\\n1.0 nan \\\\\n\\\\\n-inf 4.0 \\\\\n}"
end

@testset "table file" begin
    path = "somefile.dat"
    @test squashed_repr_tex(Table(@pgf({x = "a", y = "b"}), path)) ==
        "table[\nx={a},\ny={b}\n] {$(path)}"
    @test squashed_repr_tex(Table(path)) == "table {$(path)}"
end

@testset "plot" begin
    # sanity checks for constructors and printing, 2D
    data2 = Table(x = 1:2, y = 3:4)
    p2 = Plot(false, false, Options(), data2, [raw"\closedcycle"])
    @test squashed_repr_tex(p2) ==
        "\\addplot\ntable[\nrow sep={\\\\}\n]\n{\nx y \\\\\n1 3 \\\\\n2 4 \\\\\n}\n\\closedcycle\n;"
    @test Plot(data2, raw"\closedcycle") ≅ p2
    @test PlotInc(data2, raw"\closedcycle") ≅
        Plot(false, true, Options(), data2, [raw"\closedcycle"])
    @test PlotInc(data2, raw"\closedcycle") ≅
        Plot(false, true, PGFPlotsX.Options(), data2, [raw"\closedcycle"])
    @test Plot(data2, raw"\closedcycle") ≅ p2
    # printing incremental w/ options, 2D and 3D
    @test squashed_repr_tex(PlotInc(data2)) ==
        "\\addplot+\ntable[\nrow sep={\\\\}\n]\n{\nx y \\\\\n1 3 \\\\\n2 4 \\\\\n}\n;"
    @test squashed_repr_tex(@pgf Plot3Inc({xtick = 1:3},
                                          Table(x = 1:2, y = 3:4, z = 5:6))) ==
        "\\addplot3+[\nxtick={1,2,3}\n]\ntable[\nrow sep={\\\\}\n]\n{\nx y z \\\\\n1 3 5 \\\\\n2 4 6 \\\\\n}\n;"
end

@testset "printing and indentation" begin
    # adding indent, with corner cases for newlines
    @test PGFPlotsX.add_indent("foo") == "    foo"
    @test PGFPlotsX.add_indent("foo\n") == "    foo\n"
    @test PGFPlotsX.add_indent("foo\nbar") == "    foo\n    bar"
    @test PGFPlotsX.add_indent("foo\n\nbar\n") == "    foo\n\n    bar\n"
    @test PGFPlotsX.add_indent("\nfoo\n\nbar\n") == "\n    foo\n\n    bar\n"
    # expression
    @test repr_tex(Expression("x^2")) == "{x^2}"
    @test repr_tex(Expression(["x^2", "y^2"])) == "(\n{x^2},\n{y^2})"
    # graphics
    @test repr_tex(@pgf Graphics({ testopt = 1}, "filename")) ==
        "graphics[\n    testopt={1}\n    ] {filename}\n"
    @test repr_tex_compact(@pgf Graphics({ testopt = 1}, "filename")) ==
        "graphics[testopt={1}] {filename}\n"
    # coordinates, tables, and plot
    c = Coordinates([(1, 2), (3, 4)])
    @test repr_tex(c) == "coordinates {\n    (1,2)\n    (3,4)\n}\n"
    t = Table(x = 1:2, y = 3:4)
    @test repr_tex(t) == "table[\n    row sep={\\\\}\n    ]\n{\n    x  y  \\\\\n    1  3  \\\\\n    2  4  \\\\\n}\n"
    @test repr_tex(@pgf Plot({ no_marks }, c)) ==
        "\\addplot[\n    no marks\n    ]\n    coordinates {\n        (1,2)\n        (3,4)\n    }\n    ;\n"
    r = repr_tex(@pgf Plot({ no_marks }, t, "trailing"))
    r4 = split(r, " "^4)
    r8 = split(r, " "^8)
    ref = "\\addplot[\n    no marks\n    ]\n    table[\n        row sep={\\\\}\n        ]\n    {\n        x  y  \\\\\n" *
    "        1  3  \\\\\n        2  4  \\\\\n    }\n    trailing\n    ;\n"
    ref4 = split(ref, " "^4)
    ref8 = split(ref, " "^8)
    @test length(r8) == 6
    @test length(r4) == 18
    @test length(ref8) == 6
    @test length(ref4) == 18
    @test r == ref
    # legend
    @test repr_tex(Legend(["a", "b", "c"])) == "\\legend{{a},{b},{c}}\n"
    l = LegendEntry("a")
    @test repr_tex(l) == "\\addlegendentry {a}\n"
    # axis
    @test repr_tex(@pgf Axis({ optaxis }, Plot({ optplot }, c), l)) ==
        "\\begin{axis}[\n    optaxis\n    ]\n    \\addplot[\n        optplot\n        ]\n" *
        "        coordinates {\n            (1,2)\n            (3,4)\n        }\n" *
        "        ;\n    \\addlegendentry {a}\n\\end{axis}\n"
end

@testset "explicit empty options" begin
    @test repr_tex(Axis(Options(; print_empty = true))) ==
        "\\begin{axis}[]\n\\end{axis}\n"
end

@testset "push! and append!" begin
    plot = Plot(Expression("x"))
    push!(plot, "a")::Plot
    append!(plot, ["b", "c"])::Plot
    @test plot.trailing == ["a", "b", "c"]
    axis = Axis()
    push!(axis, plot)::Axis
    append!(axis, ["non", "sense"])::Axis
    @test axis.contents == [plot, "non", "sense"]
    picture = TikzPicture()
    push!(picture, axis)::TikzPicture
    append!(picture, ["some", "thing"])::TikzPicture
    @test picture.elements == [axis, "some", "thing"]
    document = TikzDocument()
    push!(document, picture)::TikzDocument
    append!(document, ["stuff"])::TikzDocument
    @test document.elements == [picture, "stuff"]
end

@testset "vertical and horizontal lines" begin
    @test repr_tex((@pgf VLine({blue}, 9))) ==
        "\\draw[\n    blue\n    ] ({axis cs:9,0}|-{rel axis cs:0,1}) -- ({axis cs:9,0}|-{rel axis cs:0,0});\n"
    @test repr_tex((@pgf HLine({dashed}, 4.0))) ==
        "\\draw[\n    dashed\n    ] ({rel axis cs:1,0}|-{axis cs:0,4.0}) -- ({rel axis cs:0,0}|-{axis cs:0,4.0});\n"
end

@testset "colors" begin
    @test squashed_repr_tex(@pgf { color = RGB(1e-10, 1, 1) }) ==
        "[\ncolor={rgb,1:red,0.0;green,1.0;blue,1.0}\n]"
    @test squashed_repr_tex(@pgf { color = HSV(1, 1e-10, 1) }) ==
        "[\ncolor={rgb,1:red,1.0;green,1.0;blue,1.0}\n]"
end

@testset "Axis, SemiLogXAxis, SemiLogYAxis and LogLogAxis inside GroupPlot" begin
    gp = @pgf GroupPlot({group_style={group_size="2 by 2"}},
        Axis(), SemiLogXAxis(), SemiLogYAxis(), LogLogAxis())
    @test repr_tex(gp) == """
    \\begin{groupplot}[
        group style={
            group size={2 by 2}
            }
        ]
        \\nextgroupplot
        \\nextgroupplot[
            xmode=log,ymode=normal
            ]
        \\nextgroupplot[
            xmode=normal,ymode=log
            ]
        \\nextgroupplot[
            xmode=log,ymode=log
            ]
    \\end{groupplot}
    """
end
