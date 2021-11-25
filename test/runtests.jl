using Grapher
using Test

axis_options(options::Grapher.Options) = Grapher.merge_recursive(Grapher.default_axis_options(), options)
plot_options(options::Grapher.Options) = Grapher.merge_recursive(Grapher.default_plot_options(), options)

function getcoords(x::Grapher.Axis)
    plt = only(x.contents) # `Plot`
    coords = plt.data      # `Coordinates`
    coords.data            # `Vector`
end
function getcoords(x::Grapher.Plot)
    coords = x.data      # `Coordinates`
    coords.data            # `Vector`
end


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

    @testset "lims" begin
        ax = plot(1:3, 4:6, ylims = (0,10))
        @test ax.options == axis_options(@pgf{ymin = 0, ymax = 10})
    end

    @testset "black" begin
        ax = plot(1:3, 4:6, black = true)
        @test ax.options == axis_options(@pgf{cycle_list_name = "linestyles*"})
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

    @testset "mark/marker" begin
        # mark/marker
        ax = plot([1,2,3], [4,5,6], mark = "o")
        @test only(ax.contents).options == plot_options(@pgf{mark = "o"})
        ax = plot([1,2,3], [4,5,6], marker = "o")
        @test only(ax.contents).options == plot_options(@pgf{mark = "o"})
        # mark/marker = nothing
        ax = plot([1,2,3], [4,5,6], mark = nothing)
        @test only(ax.contents).options == plot_options(@pgf{no_marks})
        ax = plot([1,2,3], [4,5,6], marker = nothing)
        @test only(ax.contents).options == plot_options(@pgf{no_marks})
        # no_marks/no_markers
        ax = plot([1,2,3], [4,5,6], no_marks = true)
        @test only(ax.contents).options == plot_options(@pgf{no_marks})
        ax = plot([1,2,3], [4,5,6], no_markers = true)
        @test only(ax.contents).options == plot_options(@pgf{no_marks})
        # only_marks/only_markers
        ax = plot([1,2,3], [4,5,6], only_marks = true)
        @test only(ax.contents).options == plot_options(@pgf{only_marks})
        ax = plot([1,2,3], [4,5,6], only_markers = true)
        @test only(ax.contents).options == plot_options(@pgf{only_marks})
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

@testset "Group plot" begin
    group = plot([plot([1,2,3], [4,5,6]), plot([1,2,3], [6,5,4])], xlabel = "xlabel", ylabel = "ylabel")
    @test getcoords(group.contents[1]) == getcoords(plot([1,2,3], [4,5,6]))
    @test getcoords(group.contents[2]) == getcoords(plot([1,2,3], [6,5,4]))
    @test group.contents[1].options == axis_options(@pgf{ylabel = "ylabel"})
    @test group.contents[2].options == axis_options(@pgf{xlabel = "xlabel", ylabel = "ylabel"})

    group = plot([plot([1,2,3], [4,5,6]) plot([1,2,3], [6,5,4])], xlabel = "xlabel", ylabel = "ylabel")
    @test getcoords(group.contents[1]) == getcoords(plot([1,2,3], [4,5,6]))
    @test getcoords(group.contents[2]) == getcoords(plot([1,2,3], [6,5,4]))
    @test group.contents[1].options == axis_options(@pgf{xlabel = "xlabel", ylabel = "ylabel"})
    @test group.contents[2].options == axis_options(@pgf{xlabel = "xlabel"})

    group = plot([plot([1,2,3], [4,5,6]) plot([1,2,3], [6,5,4])
                  plot([1,2,3], [7,8,9]) plot([1,2,3], [9,8,7])],
                 legend = "a", legend_pos = "north east")
    ax = group.contents[1]
    @test length(ax.contents) == 2
    @test ax.contents[2] isa Grapher.LegendEntry
    @test group.options["legend_pos"] == "north east"

    group = plot([plot([1,2,3], [4,5,6]) plot([1,2,3], [6,5,4])
                  plot([1,2,3], [7,8,9]) plot([1,2,3], [9,8,7])],
                 legend = "a", legend_pos = "north east", legend_pos_axis = (2,2))
    ax = group.contents[4]
    @test length(ax.contents) == 2
    @test ax.contents[2] isa Grapher.LegendEntry
    @test group.options["legend_pos"] == "north east"
end
