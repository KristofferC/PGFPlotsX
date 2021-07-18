function is_file_starting_with(filename, bytes::DenseVector{UInt8})
    isfile(filename) && read(filename, length(bytes)) == bytes
end

function is_file_starting_with(filename, regex::Regex, nlines = 1)
    isfile(filename) || return false
    content = ""
    open(filename, "r") do io
        for _ in 1:nlines
            content *= readline(io; keep = false)
        end
    end
    occursin(regex, content)
end

is_png_file(filename) = is_file_starting_with(filename, b"\x89PNG")

is_pdf_file(filename) = is_file_starting_with(filename, b"%PDF")

is_tex_document(filename) =     # may have a \Require in the first line
    is_file_starting_with(filename, r"\\documentclass\[tikz\]{standalone}", 2)

function is_tikz_standalone(filename)
    if !isfile(filename)
        return false
    end
    s = read(filename,String)
    m = match(r"^([^%].*$)"m,s) # First non-commented non-empty line
    if isnothing(m)
        return false
    end
    return occursin(r"\\begin{tikzpicture}",m.captures[1])
end

is_svg_file(filename) = is_file_starting_with(filename, r"<svg .*>", 2)

@testset "preamble" begin
    mktemp() do path, f
        withenv("PGFPLOTSX_PREAMBLE_PATH" => path) do
            try
                test_preamble_env = "test preamble env"
                test_preamble_var = "test preamble var"

                push!(PGFPlotsX.CUSTOM_PREAMBLE, test_preamble_var)
                print(f, test_preamble_env)
                close(f)

                td = TikzDocument()

                io = IOBuffer()
                PGFPlotsX.savetex(io, td)

                texstring = String(take!(io))
                @test occursin(test_preamble_env, texstring)
                @test occursin(test_preamble_var, texstring)
            finally
                empty!(PGFPlotsX.CUSTOM_PREAMBLE)
            end
        end
    end
end

@testset "simple" begin
    tmp = tempname()
    mktempdir() do dir
        cd(dir) do
            a = Axis(Plot(Expression("x^2")))
            pgfsave("$tmp.tex", a)
            @test is_tex_document("$tmp.tex")
            println(read("$tmp.tex", String))
            if PGFPlotsX.png_engine() !== PGFPlotsX.NO_PNG_ENGINE
                pgfsave("$tmp.png", a)
                @test is_png_file("$tmp.png")
            else
                @test_throws PGFPlotsX.MissingExternalProgramError pgfsave("$tmp.png", a)
            end
            if PGFPlotsX.svg_engine() !== PGFPlotsX.NO_SVG_ENGINE
                pgfsave("$tmp.svg", a)
                @test is_svg_file("$tmp.svg")
            else
                @test_throws PGFPlotsX.MissingExternalProgramError pgfsave("$tmp.svg", a)
            end
            pgfsave("$tmp.pdf", a)
            @test is_pdf_file("$tmp.pdf")
            pgfsave("$tmp.tikz", a)
            @test is_tikz_standalone("$tmp.tikz")
            # test with filename::String{SubString}
            pgfsave(split("foo|$tmp-2.pdf", '|')[2], a)
            @test is_pdf_file("$tmp-2.pdf")

            let tikz_lines = readlines("$tmp.tikz")
                last_line = findlast(!isempty, tikz_lines)
                @test strip(tikz_lines[last_line]) == "\\end{tikzpicture}"
            end
        end
    end
end

@testset "show(io, mime, plot)" begin; mktempdir() do dir; cd(dir) do
    tmp = tempname()
    io = IOBuffer()
    a = Axis(Plot(Expression("x^2")))
    # pdf
    let tmp = tmp * ".pdf", mime = MIME"application/pdf"()
        show(io, mime, a)
        write(tmp, take!(io))
        @test is_pdf_file(tmp)
        rm(tmp; force=true)
    end
    # svg
    let tmp = tmp * ".svg", mime = MIME"image/svg+xml"()
        if PGFPlotsX.svg_engine() !== PGFPlotsX.NO_SVG_ENGINE
            show(io, mime, a)
            write(tmp, take!(io))
            @test is_svg_file(tmp)
            rm(tmp; force=true)
        else
            @test_throws MethodError show(io, mime, a)
        end
    end
    # png
    let tmp = tmp * ".png", mime = MIME"image/png"()
        if PGFPlotsX.png_engine() !== PGFPlotsX.NO_PNG_ENGINE
            show(io, mime, a)
            write(tmp, take!(io))
            @test is_png_file(tmp)
            rm(tmp; force=true)
        else
            @test_throws MethodError show(io, mime, a)
        end
    end
end end end

@testset "gnuplot / shell-escape" begin
    if HAVE_GNUPLOT
        tmp_pdf = tempname() * ".pdf"
        expr = "-2.051^3*1000./(2*3.1415*(2.99*10^2)^2)/(x^2*cos(y)^2)"
        mktempdir() do dir
            cd(dir) do
                @pgf p =
                    Axis(
                        {
                            colorbar,
                            xlabel = "x",
                            ylabel = "y",
                            domain = "1:2",
                            y_domain = "74:87.9",
                            view = (0, 90),
                        },
                        Plot3(
                            {
                                contour_gnuplot = {
                                    number = 30,
                                    labels = false},
                                thick,
                                samples = 40,
                            },
                            Expression(expr)))
                pgfsave(tmp_pdf, p)
                @test is_pdf_file(tmp_pdf)
                rm(tmp_pdf)
            end
        end
    end
end

@testset "legend to name; ref" begin
    tmp_pdf = tempname() * ".pdf"
    mktempdir() do dir
        cd(dir) do
            @pgf a = [Axis({legend_to_name = "named",
                            title = "k = $k", legend_columns = 2,
                            legend_entries = {"\$x^k\$", "\$(x + 1)^k\$"}},
                            PlotInc(Expression("x^$k")),
                            PlotInc(Expression("(x + 1)^$k")))
                      for k in 1:3]
            p = TikzPicture("\\matrix{", a[1], "&", a[2], "&", a[3], raw"\\\\};",
                            raw"\node at (.5, -4.5) {\ref{named}};")
            pgfsave(tmp_pdf, p)
            @test is_pdf_file(tmp_pdf)
            rm(tmp_pdf)
        end
    end
end

@testset "class options" begin
    tmp_pdf = tempname() * ".pdf"
    mktempdir() do dir
        cd(dir) do
            PGFPlotsX.CLASS_OPTIONS[1] = "varwidth"
            push!(PGFPlotsX.CLASS_OPTIONS, "crop = false")
            td = TikzDocument("\\begin{tabular}{cc}",
                              TikzPicture(Axis(Plot(Expression("x^2")))),
                              "& A \\end{tabular}")
            pgfsave(tmp_pdf, td)
            @test is_pdf_file(tmp_pdf)
            rm(tmp_pdf)
        end
    end
end
