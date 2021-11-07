using Grapher
using Test

using Grapher: recursive_merge


@testset "Axis options" begin
    ax = plot([1,2,3], [4,5,6])
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 1
    @test ax.options == Grapher.default_axis_options()

    ax = plot([1,2,3], [4,5,6],
              xlabel = "abc",
              not_supported_option = "abc",
              axis_options = @pgf{xlabel = "def",
                                  ylabel = "def",}, # this should be overwritten by above `xlabel` option
             )
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 1
    @test ax.options == recursive_merge(@pgf{xlabel = "abc", ylabel = "def"}, Grapher.default_axis_options())

    @testset "size" begin
        ax = plot([1,2,3], [4,5,6], size = "landscape")
        @test ax.options == recursive_merge(@pgf{width = "80mm", height = "50mm"}, Grapher.default_axis_options())
        ax = plot([1,2,3], [4,5,6], size = "portrait")
        @test ax.options == recursive_merge(@pgf{width = "50mm", height = "80mm"}, Grapher.default_axis_options())
        ax = plot([1,2,3], [4,5,6], size = "square")
        @test ax.options == recursive_merge(@pgf{width = "80mm", height = "80mm"}, Grapher.default_axis_options())
    end

    @testset "xtick, ytick, ztick" begin
        ax = plot(["a","b","c"], [4,5,6], xtick = ["c","b","a"])
        @test ax.options == recursive_merge(@pgf{symbolic_x_coords = ["c","b","a"], xtick = "data"}, Grapher.default_axis_options())
    end
end

@testset "Legend" begin
    ax = plot([1,2,3], [4,5,6],
              legend = "abc",
              legend_pos = "north east",
             )
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 2
    @test ax.contents[2] isa Grapher.LegendEntry
    @test ax.options == recursive_merge(@pgf{legend_pos = "north east"}, Grapher.default_axis_options())

    ax = plot([1,2,3], [4,5,6],
              legend_pos = (0.5, 0.0),
             )
    @test ax.options == Grapher.recursive_merge(@pgf{legend_style = {at = Grapher.Coordinate(0.5, 0.0)}}, Grapher.default_axis_options())
end

@testset "Plot options" begin
    ax = plot([1,2,3], [4,5,6])
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 1
    plt = only(ax.contents)
    @test plt.options == Grapher.default_plot_options()

    ax = plot([1,2,3], [4,5,6],
              color = "red",
              plot_options = @pgf{color = "blue", # this should be overwritten by above `xlabel` option
                                  marker = "o",}, # given option is passed without modifications in `plot_options`
             )
    plt = only(ax.contents)
    @test plt.options == recursive_merge(@pgf{color = "red", marker = "o"}, Grapher.default_plot_options())

    @testset "marker" begin
        ax = plot([1,2,3], [4,5,6], marker = "o")
        plt = only(ax.contents)
        @test plt.options == recursive_merge(@pgf{mark = "o"}, Grapher.default_plot_options())

        ax = plot([1,2,3], [4,5,6], marker = nothing)
        plt = only(ax.contents)
        @test plt.options == recursive_merge(@pgf{no_marks}, Grapher.default_plot_options())
    end

    @testset "line_style" begin
        ax = plot([1,2,3], [4,5,6], line_style = "dotted")
        plt = only(ax.contents)
        @test plt.options == recursive_merge(@pgf{dotted}, Grapher.default_plot_options())
    end

    @testset "line_width" begin
        ax = plot([1,2,3], [4,5,6], line_width = "thick")
        plt = only(ax.contents)
        @test plt.options == recursive_merge(@pgf{thick}, Grapher.default_plot_options())

        ax = plot([1,2,3], [4,5,6], line_width = nothing)
        plt = only(ax.contents)
        @test plt.options == recursive_merge(@pgf{draw = "none"}, Grapher.default_plot_options())
    end

    @testset "on/off options" begin
        for name in (:smooth, :only_marks, :no_marks)
            @eval begin
                ax = plot([1,2,3], [4,5,6], $name = true)
                plt = only(ax.contents)
                @test plt.options == recursive_merge(@pgf{$name}, Grapher.default_plot_options())
            end
        end
    end
end
