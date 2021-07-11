# test that the @pfg macro is expanded correctly

module TestModule
using PGFPlotsX: @pgf
testpgf() = @pgf { ymax = 1 }
end

@testset "pgf escape" begin
    # just testing that it is escaped and evaluated
    @test TestModule.testpgf() ≠ nothing
end

@testset "pgf tests" begin
    a = 1
    b = 2
    theme = @pgf {color = "white"}
    opt = @pgf { xmax = a + b, title = "42", justkey, raw"rawstring", theme... }
    @test opt["color"] == "white"
    @test repr_tex(opt) == repr_tex(Options("xmax" => 3, "title" => "42", "justkey" => nothing,
                                            "rawstring" => nothing, "color" => "white"))
    f(x...) = tuple(x...)
    y = @pgf f({ look, we, are = f(1, 2, 3), nesting = { stuff = 9 }})
    @test length(y) == 1
    @test repr_tex(y[1]) == repr_tex(Options("look" => nothing,
                                             "we" => nothing,
                                             "are" => (1, 2, 3),
                                             "nesting" => Options("stuff" => 9)))
end

@testset "pgf empty" begin
    @test squashed_repr_tex(@pgf Plot({}, Table("x" => [1,2,3]))) ==
        "\\addplot[]\ntable[\nrow sep={\\\\}\n]\n{\nx \\\\\n1 \\\\\n2 \\\\\n3 \\\\\n}\n;" # note []
    @test squashed_repr_tex(@pgf Plot({}, Table([], []))) ==
        "\\addplot[]\ntable[\nrow sep={\\\\}\n]\n{\n\\\\\n}\n;" # note []
end

@testset "operations on options" begin
    O1 = @pgf { a = 1 }

    # copy
    O2 = copy(O1)
    @test O1 ≅ O2

    # merge
    @test merge(O1, @pgf { b = 2 }) ≅ @pgf { a = 1, b = 2 }
    O3 = @pgf { a = 1, b = 2, c = 3 }
    @test merge(O1, @pgf({ b = 2 }), @pgf({ c = 3 })) ≅ O3

    # merge!
    @test merge!(O1, @pgf({ b = 2 }), @pgf({ c = 3 })) ≡ O1
    @test O1 ≅ O3

    # merge! for OptionType
    P = Plot(O2, Table([1], [1])); # don't print, nonsensical
    @test merge!(P, @pgf({ b = 2 }), @pgf({ c = 3 })) ≡ P
    @test P.options ≅ O3
end
  
@testset "options push! and append!" begin
    opt1 = "color" => "red"
    opt2 = "dashed"
    @test @pgf(push!({}, opt1, opt2)::Options).dict == Dict([opt1, opt2 => nothing])
    @test @pgf(append!({}, [opt1, opt2])::Options).dict == Dict([opt1, opt2 => nothing])
end

@testset "options constructor" begin
    opts = PGFPlotsX.Options(
        "fill" => "foo",
        "draw opacity" => 0.1
    )
    @test opts.dict == Dict("fill" => "foo", "draw opacity" => 0.1)
end

@testset "options haskey" begin
    opts = PGFPlotsX.Options("foo" => "bar")
    @test haskey(opts, "foo")
end
