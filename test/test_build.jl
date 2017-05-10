@testset "engine" begin
    try
        pgf.latexengine!(pgf.XELATEX)
        @test pgf.latexengine() == pgf.XELATEX
        @test pgf._engine_cmd() == `xelatex`
    finally
        pgf.latexengine!(pgf.LUALATEX)
    end
end

@testset "preamble" begin
    mktemp() do path, f
        withenv("PGFPLOTSX_PREAMBLE_PATH" => path) do
            try
                test_preamble_env = "test preamble env"
                test_preamble_var = "test preamble var"

                push!(pgf.CUSTOM_PREAMBLE, test_preamble_var)
                print(f, test_preamble_env)
                close(f)

                io = IOBuffer()
                pgf._print_preamble(io)

                preamble = String(take!(io))
                @test contains(preamble, test_preamble_env)
                @test contains(preamble, test_preamble_var)
            finally
                empty!(pgf.CUSTOM_PREAMBLE)
            end
        end
    end
end

@testset "gnuplot / shell-escape" begin
    pgf.@pgf p = pgf.Axis(pgf.Plot3(pgf.Expression("-2.051^3*1000./(2*3.1415*(2.99*10^2)^2)/(x^2*cos(y)^2)"),
            {
                contour_gnuplot = {number = 30, labels = false},
                thick,
                samples = 40,
            }; incremental = false),
        {
            colorbar,
            xlabel = "x",
            ylabel = "y",
            domain = 1:2,
            y_domain = "74:87.9",
            view = (0, 90),
        })

        path, name = tempdir(), tempname()
        pdf_file = joinpath(path, name) * ".pdf"
        pgf.save(pdf_file, p)
        @test isfile(pdf_file)
        rm(pdf_file)
end
