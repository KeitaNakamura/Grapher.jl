using Grapher
using Test

axis_options(options::Grapher.Options) = Grapher.merge_recursive(Grapher.default_axis_options(), options)
plot_options(options::Grapher.Options) = Grapher.merge_recursive(Grapher.default_plot_options(), options)


@testset "Axis options" begin
    ax = plot([1,2,3], [4,5,6])
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 1
    @test ax.options == Grapher.default_axis_options()

    ax = plot([1,2,3], [4,5,6],
              xlabel = "foo",
              not_supported_option = "foo",
              axis_options = @pgf{xlabel = "bar",
                                  ylabel = "bar",}, # this should be overwritten by above `xlabel` option
             )
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 1
    @test ax.options == axis_options(@pgf{xlabel = "foo", ylabel = "bar"})

    @testset "size" begin
        ax = plot([1,2,3], [4,5,6], size = "landscape")
        @test ax.options == axis_options(@pgf{width = "80mm", height = "50mm"})
        ax = plot([1,2,3], [4,5,6], size = "portrait")
        @test ax.options == axis_options(@pgf{width = "50mm", height = "80mm"})
        ax = plot([1,2,3], [4,5,6], size = "square")
        @test ax.options == axis_options(@pgf{width = "80mm", height = "80mm"})
    end

    @testset "xtick, ytick, ztick" begin
        ax = plot(["a","b","c"], [4,5,6], xtick = ["c","b","a"])
        @test ax.options == axis_options(@pgf{symbolic_x_coords = ["c","b","a"], xtick = "data"})
    end
end

@testset "Legend" begin
    ax = plot([1,2,3], [4,5,6],
              legend = "foo",
              legend_pos = "north east",
             )
    @test isa(ax, Grapher.Axis)
    @test length(ax.contents) == 2
    @test ax.contents[2] isa Grapher.LegendEntry
    @test ax.options == axis_options(@pgf{legend_pos = "north east"})

    ax = plot([1,2,3], [4,5,6],
              legend_pos = (0.5, 0.0),
             )
    @test ax.options == axis_options(@pgf{legend_style = {at = Grapher.Coordinate(0.5, 0.0)}})
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
    @test plt.options == plot_options(@pgf{color = "red", marker = "o"})

    @testset "marker" begin
        ax = plot([1,2,3], [4,5,6], marker = "o")
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{mark = "o"})

        ax = plot([1,2,3], [4,5,6], marker = nothing)
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{no_marks})
    end

    @testset "line_style" begin
        ax = plot([1,2,3], [4,5,6], line_style = "dotted")
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{dotted})
    end

    @testset "line_width" begin
        ax = plot([1,2,3], [4,5,6], line_width = "thick")
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{thick})

        ax = plot([1,2,3], [4,5,6], line_width = nothing)
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{draw = "none"})
    end

    @testset "on/off options" begin
        for name in (:smooth, :only_marks, :no_marks)
            @eval begin
                ax = plot([1,2,3], [4,5,6], $name = true)
                plt = only(ax.contents)
                @test plt.options == plot_options(@pgf{$name})
            end
        end
    end
end

@testset "Plots" begin
    function getcoords(x::Grapher.Axis)
        plt = only(x.contents) # `Plot`
        coords = plt.data      # `Coordinates`
        coords.data            # `Vector`
    end
    function getcoords(x::Grapher.Plot)
        coords = x.data      # `Coordinates`
        coords.data            # `Vector`
    end

    @testset "with functions" begin
        @test getcoords(plot([1,2,3], x -> x + 3)) == getcoords(plot([1,2,3], [4,5,6]))
        @test getcoords(plot(y -> 2y, [1,2,3])) == getcoords(plot([2,4,6], [1,2,3]))
        @test_throws Exception plot(y -> 2y, x -> x + 3)
    end

    @testset "map options" begin
        @test getcoords(plot([1,2,3], x -> x + 3, xmap = x->2x, ymap = -)) == getcoords(plot([2,4,6], -[4,5,6]))
    end

    @testset "csv file" begin
        axis = plot("table.csv", :a, [:b, :c])
        @test getcoords(axis.contents[1]) == getcoords(plot("table.csv", :a, :b))
        @test getcoords(axis.contents[2]) == getcoords(plot("table.csv", :a, :c))
    end
end
