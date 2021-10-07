module Grapher

using Reexport

using PGFPlotsX
using PGFPlotsX: Options as Opts
export @pgf

@reexport using LaTeXStrings

using Interpolations


export
    plot,
    plot!,
    scatter,
    plot_fillbetween

const axis_attributes = Dict(
    :xlabel => :xlabel,
    :ylabel => :ylabel,
    :xmin => :xmin,
    :ymin => :ymin,
    :legend_pos => :legend_pos,
    :minorticks => :minor_tick_num,
)
const plot_attributes = Dict(
    :marker => :mark,
    :color => :color,
    :fill => :fill,
    :opacity => :opacity,
    :line_width => :line_width,
)
const mark_attributes = Dict(
    :marker_fill => :fill,
    :marker_scale => :scale,
)

const default_axis_options = @pgf{legend_cell_align = "left"}
const default_plot_options = @pgf{}
const default_mark_options = @pgf{}


function fixoptions!(options::Opts)
    if haskey(options, :mark)
        if options[:mark] === nothing
            delete!(options, :mark)
            options[:no_marks] = nothing # set no_marks
        end
    end
    if haskey(options, :line_width)
        options[Symbol(options[:line_width])] = nothing # set line_width
        delete!(options, :line_width)
    end
end
function fixoptions!(plt::Plot)
    fixoptions!(plt.options)
    plt
end
function GrapherAxis(options::Opts, contents...)
    fixoptions!(options)
    foreach(fixoptions!, contents)
    Axis(options, contents...)
end

function plot(obj = nothing;
              axis_options = @pgf{},
              plot_options = @pgf{},
              mark_options = @pgf{},
              kwargs...)
    merge!(axis_options, Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...))
    merge!(plot_options, Opts((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...))
    merge!(mark_options, Opts((mark_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(mark_attributes, key))...))

    if obj === nothing
        plt = ()
    else
        plt = PlotInc(
            merge(
                default_plot_options, plot_options,
                Opts(:mark_options => merge(default_mark_options, mark_options))
            ),
            obj,
        ) |> tuple
    end

    GrapherAxis(
        merge(default_axis_options, axis_options),
        plt...,
        (haskey(kwargs, :legend) ? (LegendEntry(kwargs[:legend]),) : ())...
    )
end

function plot(x, y;
              axis_options = @pgf{},
              plot_options = @pgf{},
              mark_options = @pgf{},
              kwargs...)
    plot(Coordinates(x, y); axis_options, plot_options, mark_options, kwargs...)
end

function plot(x::Axis, ys::Axis...; kwargs...)
    options = merge(getproperty.((x, ys...), :options)...)
    plot!(GrapherAxis(options), x, ys...; kwargs...)
end

function plot!(dest::Axis, srcs::Axis...; kwargs...)
    axis_options = Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...)
    merge!(dest.options, axis_options)
    for src in srcs
        append!(dest, src.contents)
    end
    dest
end

function scatter(args...;
                 axis_options = @pgf{},
                 plot_options = @pgf{},
                 mark_options = @pgf{},
                 kwargs...)
    plot_options[:only_marks] = nothing
    plot(args...; axis_options, plot_options, mark_options, kwargs...)
end

struct FillBetween{X_Lower, Y_Lower, X_Upper, Y_Upper}
    x_lower::X_Lower
    y_lower::Y_Lower
    x_upper::X_Upper
    y_upper::Y_Upper
end

function plot_fillbetween(x_lower::AbstractVector, lower::AbstractVector, x_upper::AbstractVector, upper::AbstractVector; kwargs...)
    push!(PGFPlotsX.CUSTOM_PREAMBLE, raw"\usepgfplotslibrary{fillbetween}")
    axis_option = Opts((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...)
    line_option = Opts((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...)
    fill_option = copy(line_option)
    if !haskey(fill_option, :opacity) && !haskey(kwargs, :fill_opacity)
        fill_option[:opacity] = 0.2
    end
    if haskey(kwargs, :fill_opacity)
        fill_option[:opacity] = kwargs[:fill_opacity]
    end
    if haskey(line_option, :opacity)
        delete!(line_option, :opacity)
    end
    if haskey(kwargs, :nobounds) && kwargs[:nobounds] == true
        line_option[:opacity] = 0.0
    end
    GrapherAxis(axis_option,
         Plot(merge(@pgf{"name path=lower", no_marks}, line_option), Coordinates(x_lower, lower)),
         Plot(merge(@pgf{"name path=upper", no_marks}, line_option), Coordinates(x_upper, upper)),
         Plot(fill_option,
              raw"fill between [of=lower and upper]"))
end
function plot_fillbetween(x::AbstractVector, lower::AbstractVector, upper::AbstractVector; kwargs...)
    plot_fillbetween(x, lower, x, upper; kwargs...)
end
function plot(obj::FillBetween; kwargs...)
    plot_fillbetween(obj.x_lower, obj.y_lower, obj.x_upper, obj.y_upper; kwargs...)
end

moving_average(vs, n) = [sum(@view vs[i:(i+n-1)])/n for i in 1:(length(vs)-(n-1))]
function moving_average(x::AbstractVector, y::AbstractVector, n::Int = 10)
    @assert length(x) == length(y)
    x′ = moving_average(x, n)
    y′ = moving_average(y, n)
    isempty(x′) && return plot(), plot()
    flip = false
    if !issorted(x′) # handle unsorted x for interpolation
        x, y = y, x
        x′, y′ = y′, x′
        flip = true
    end
    interp = LinearInterpolation(x′, y′, extrapolation_bc=Line())
    lower = vcat([[x[i] y[i]] for i in 1:length(x) if y[i] ≤ interp(x[i])]...)
    upper = vcat([[x[i] y[i]] for i in 1:length(x) if y[i] > interp(x[i])]...)
    if flip
        Coordinates(y′, x′), FillBetween(lower[:,2], lower[:,1], upper[:,2], upper[:,1])
    else
        Coordinates(x′, y′), FillBetween(lower[:,1], lower[:,2], upper[:,1], upper[:,2])
    end
end

function plot_moving_average(x::AbstractVector, y::AbstractVector, n::Int = 10; kwargs...)
    plt1, plt2 = moving_average(x, y, n)
    plot(plot(plt1; kwargs...), plot(plt2; nobounds = true, kwargs...))
end

end # module
