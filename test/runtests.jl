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
        ax = plot([1,2,3], [4,5,6], size = ("6cm", "4cm"))
        @test ax.options == axis_options(@pgf{width = "6cm", height = "4cm"})
    end

    @testset "xtick, ytick, ztick" begin
        ax = plot(["a","b","c"], [4,5,6], xtick = ["c","b","a"])
        @test ax.options == axis_options(@pgf{symbolic_x_coords = ["c","b","a"], xtick = "data"})
    end

    @testset "xtick_precision, ytick_precision, ztick_precision" begin
        ax = plot([0.001, 0.01, 0.1], [0.001, 0.01, 0.1], xtick_precision = 3)
        @test ax.options == axis_options(@pgf{scaled_x_ticks = false, x_tick_label_style = {"/pgf/number format/fixed", "/pgf/number format/precision" = 3}})
    end

    @testset "logtick_fixed" begin
        ax = plot([0.001, 0.01, 0.1], [0.001, 0.01, 0.1], logtick_fixed = true)
        @test ax.options == axis_options(@pgf{log_ticks_with_fixed_point})
    end

    @testset "lims" begin
        ax = plot(1:3, 4:6, ylims = (0,10))
        @test ax.options == axis_options(@pgf{ymin = 0, ymax = 10})
    end

    @testset "xdir, ydir, zdir" begin
        ax = plot(1:3, 4:6, xdir = "reverse")
        @test ax.options == axis_options(@pgf{x_dir = "reverse"})
    end

    @testset "black" begin
        ax = plot(1:3, 4:6, black = true)
        @test ax.options == axis_options(@pgf{cycle_list_name = "linestyles*"})
    end

    @testset "on/off options" begin
        for name in (:grid,)
            @eval begin
                ax = plot([1,2,3], [4,5,6], $name = true)
                @test ax.options == axis_options(@pgf{$name})
            end
        end
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
        # mark_repeat/marker_repeat
        ax = plot(1:10, 1:10, mark_repeat = 2)
        @test only(ax.contents).options == plot_options(@pgf{mark_repeat = 2})
        ax = plot(1:10, 1:10, marker_repeat = 2)
        @test only(ax.contents).options == plot_options(@pgf{mark_repeat = 2})
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
        for name in (:smooth, :only_marks, :no_marks, :scatter)
            @eval begin
                ax = plot([1,2,3], [4,5,6], $name = true)
                plt = only(ax.contents)
                @test plt.options == plot_options(@pgf{$name})
            end
        end
        for name in (:surf, :mesh)
            @eval begin
                ax = plot([1,2,3], [4,5,6], rand(3,3), $name = true)
                plt = only(ax.contents)
                @test plt.options == plot_options(@pgf{$name})
            end
        end
    end

    @testset "black" begin
        ax = plot(1:3, 4:6, black = true)
        plt = only(ax.contents)
        @test plt.options == plot_options(@pgf{color = "black"})
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

    @testset "missing" begin
        plt = plot(1:5, [1.0,2.0,missing,4.0,5.0])
        @test getcoords(plt) == getcoords(plot(1:5, [1.0,2.0,NaN,4.0,5.0]))
        @test getcoords(plt)[3] === nothing
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

    group = plot([plot([1,2,3], [4,5,6]) plot([1,2,3], [6,5,4])
                  plot([1,2,3], [7,8,9]) plot([1,2,3], [9,8,7])],
                 horizontal_sep = "2.0cm",
                 vertical_sep = "3.0cm")
    @test group.options["group_style"]["horizontal_sep"] == "2.0cm"
    @test group.options["group_style"]["vertical_sep"] == "3.0cm"
end

@testset "Save graph" begin
    plt = plot([1,2,3], [4,5,6])
    savegraph("test1.pdf", plt)
    plt |> savegraph("test2.pdf")
    @test isfile("test1.pdf")
    @test isfile("test2.pdf")
end
