function Base.:(==)(a::Options, b::Options)
    (a.print_empty == b.print_empty) && (a.dict == b.dict)
end

Base.keys(x::Options) = keys(x.dict)
Base.values(x::Options) = values(x.dict)

Base.get(x::Options, name, default) = get(x.dict, name, default)
Base.get!(x::Options, name, default) = get!(x.dict, name, default)

merge_recursive!(dest) = dest
function merge_recursive!(dest, src, args...)
    merge_recursive!(dest, src)
    merge_recursive!(dest, args...)
end

merge_recursive!(dest::PGFPlotsX.AxisLike, src::Options) = (merge_recursive!(dest.options, src); dest)
merge_recursive!(dest::Plot, src::Options) = (merge_recursive!(dest.options, src); dest)
function merge_recursive!(dest::Options, src::Options)
    for name in keys(src.dict)
        if haskey(dest, name)
            if dest[name] isa Options && src[name] isa Options
                merge_recursive!(dest[name], src[name])
            else
                dest[name] = src[name]
            end
        else
            dest[name] = src[name]
        end
    end
    dest
end

merge_recursive(args...) = merge_recursive!(@pgf{}, args...)

function fix_axis_options!(options::Options)
    # size of figure
    if haskey(options, "size")
        sz = options["size"]
        if sz == "landscape"
            options["width"]  = "80mm"
            options["height"] = "50mm"
        elseif sz == "large landscape"
            options["width"]  = "140mm"
            options["height"] = "90mm"
        elseif sz == "portrait"
            options["width"]  = "50mm"
            options["height"] = "80mm"
        elseif sz == "large portrait"
            options["width"]  = "90mm"
            options["height"] = "140mm"
        elseif sz == "square"
            options["width"]  = "80mm"
            options["height"] = "80mm"
        elseif sz == "large square"
            options["width"]  = "140mm"
            options["height"] = "140mm"
        elseif sz isa Tuple{String, String}
            options["width"]  = sz[1]
            options["height"] = sz[2]
        end
        delete!(options, "size")
    end

    # for legend style
    if !haskey(options, "legend_style")
        options["legend_style"] = @pgf{}
    end
    legend_style = options["legend_style"]
    if haskey(options, "legend_pos")
        if options["legend_pos"] isa String
            # allow `legend_pos = "outer south"`
            if options["legend_pos"] == "outer south"
                legend_style["at"] = Coordinate(0.5, -0.15)
                legend_style["anchor"] = "north"
                legend_style["legend_columns"] = "-1"
                # legend_style[:inner_sep] = "1mm"
                legend_style["style"] = @pgf{column_sep = "2mm"}
                delete!(options, "legend_pos")
            end
        else
            # allow `legend_pos = (x, y)`
            legend_style["at"] = Coordinate(options["legend_pos"]...)
            delete!(options, "legend_pos")
        end
    end
    if haskey(options, "legend_anchor")
        legend_style["anchor"] = options["legend_anchor"]
        delete!(options, "legend_anchor")
    end

    # tick
    for name in ("xtick", "ytick", "ztick")
        if haskey(options, name)
            if options[name] isa Union{Vector{<: AbstractString}, Tuple{Vararg{AbstractString}}}
                options[string("symbolic_", name[1], "_coords")] = collect(options[name])
                options[name] = "data"
            end
            if options[name] isa Tuple
                options[name] = collect(options[name])
            end
        end
    end

    # tick_precision
    for name in ("xtick_precision", "ytick_precision", "ztick_precision")
        if haskey(options, name)
            dir = name[1]
            options["scaled_$(dir)_ticks"] = false
            tick_label_style = get!(options, "$(dir)_tick_label_style", @pgf{})
            tick_label_style["/pgf/number format/fixed"] = nothing
            tick_label_style["/pgf/number format/precision"] = options[name]
            delete!(options, name)
        end
    end

    if get(options, "logtick_fixed", false)
        options["log_ticks_with_fixed_point"] = nothing
        delete!(options, "logtick_fixed")
    end

    # lims
    for name in ("xlims", "ylims", "zlims")
        if haskey(options, name)
            dir = name[1]
            min, max = options[name]
            options[string(dir, "min")] = min
            options[string(dir, "max")] = max
            delete!(options, name)
        end
    end

    # black
    if haskey(options, "black")
        if options["black"]
            options["cycle_list_name"] = "linestyles*"
        end
        delete!(options, "black")
    end

    # on/off options
    on_off_options = ["grid"]
    for name in on_off_options
        if haskey(options, name)
            if options[name] == true
                options[name] = nothing
            else
                delete!(options, name)
            end
        end
    end

    options
end

function fix_plot_options!(options::Options)
    # give only `{key}` not `{key = value}`
    key_options = ["line_style"]
    for name in key_options
        if haskey(options, name)
            pgf_name = options[name]
            options[pgf_name] = nothing
            delete!(options, name)
        end
    end

    # line_width
    if haskey(options, "line_width")
        if options["line_width"] in ["ultra thin", "very thin", "thin", "semithick", "thick", "very thick", "ultra thick"]
            options[options["line_width"]] = nothing
            delete!(options, "line_width")
        elseif options["line_width"] === nothing
            options["draw"] = "none"
            delete!(options, "line_width")
        end
    end

    # on/off options
    on_off_options = ["smooth", "only_marks", "no_marks", "surf", "mesh", "scatter", "grid"]
    for name in on_off_options
        if haskey(options, name)
            if options[name] == true
                options[name] = nothing
            else
                delete!(options, name)
            end
        end
    end

    # allow `marker = nothing`
    if haskey(options, "mark")
        if options["mark"] === nothing
            delete!(options, "mark")
            options["no_marks"] = nothing # set no_marks
        end
    end

    # black
    if haskey(options, "black")
        if options["black"]
            options["color"] = "black"
        end
        delete!(options, "black")
    end

    options
end

function fix_mark_options!(options::Options)
    options
end

extract_axis_options(; kwargs...) = fix_axis_options!(Options((axis_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(axis_attributes, key))...))
extract_plot_options(; kwargs...) = fix_plot_options!(Options((plot_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(plot_attributes, key))...))
extract_mark_options(; kwargs...) = fix_mark_options!(Options((mark_attributes[key] => value for (key, value) in pairs(kwargs) if haskey(mark_attributes, key))...))

set_axis_options!(a::Any; kwargs...) = a
function set_axis_options!(a::PGFPlotsX.AxisLike; axis_options = @pgf{}, kwargs...)
    merge_recursive!(a, axis_options, extract_axis_options(; kwargs...))
    a
end

set_plot_options!(p::Any; kwargs...) = p
function set_plot_options!(p::Plot; plot_options = @pgf{}, mark_options = @pgf{}, kwargs...)
    merge_recursive!(p, plot_options, extract_plot_options(; kwargs...))
    if !haskey(p.options, "mark_options")
        p["mark_options"] = @pgf{}
    end
    merge_recursive!(p["mark_options"], mark_options, extract_mark_options(; kwargs...))
    p
end
function set_plot_options!(a::PGFPlotsX.AxisLike; kwargs...)
    for c in a.contents
        set_plot_options!(c; kwargs...)
    end
end
