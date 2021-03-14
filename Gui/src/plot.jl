## Plot Info

Base.:(==)(r1::ImPlot.ImPlotRange, r2::ImPlot.ImPlotRange) = (r1.Min == r2.Min && r1.Max == r2.Max)
Base.:(==)(p1::ImPlot.ImPlotLimits, p2::ImPlot.ImPlotLimits) = p1.X == p2.X && p1.Y == p2.Y

mutable struct PlotXAxisLink
    XMin::Ref{Cdouble}
    XMax::Ref{Cdouble}

    PlotXAxisLink() = new(Ref(0.0), Ref(0.0))
end

mutable struct PlotYAxisLink
    YMin::Ref{Cdouble}
    YMax::Ref{Cdouble}
    Y2Min::Ref{Cdouble}
    Y2Max::Ref{Cdouble}
    Y3Min::Ref{Cdouble}
    Y3Max::Ref{Cdouble}

    PlotYAxisLink() = new(Ref(0.0), Ref(0.0), Ref(0.0), Ref(0.0), Ref(0.0), Ref(0.0))
end

Base.@kwdef mutable struct PlotInfo
    PlotLimits::Tracked{ImPlot.ImPlotLimits} = Tracked{ImPlot.ImPlotLimits}()
    PlotYAxisLink::PlotYAxisLink             = PlotYAxisLink()
    PlotXAxisLink::PlotXAxisLink             = PlotXAxisLink()
    Reset::Bool                              = true
end

const PlotInfoCache = Dict{Int,PlotInfo}()

getplotinfo(plotid) = get!(() -> PlotInfo(), PlotInfoCache, plotid)    

xmin(plotinfo::PlotInfo) = plotinfo.PlotLimits[].X.Min
xmax(plotinfo::PlotInfo) = plotinfo.PlotLimits[].X.Max
ymin(plotinfo::PlotInfo) = plotinfo.PlotLimits[].Y.Min
ymax(plotinfo::PlotInfo) = plotinfo.PlotLimits[].Y.Max

## Plot Linking

const PlotLinks = Dict{Int,PlotXAxisLink}()

function linkxaxis!(plotinfo::PlotInfo, linkid::Int)
    plotinfo.PlotXAxisLink = get!(() -> PlotXAxisLink(), PlotLinks, linkid)
    xaxislink = plotinfo.PlotXAxisLink
    yaxislink = plotinfo.PlotYAxisLink
    ImPlot.LinkNextPlotLimits(xaxislink.XMin, xaxislink.XMax, yaxislink.YMin, yaxislink.YMax, yaxislink.Y2Min, yaxislink.Y2Max, yaxislink.Y3Min, yaxislink.Y3Max)
end

function plot(inner, title_id::String, x_label::AbstractString, y_label::AbstractString, size::Tuple{Real,Real};
    xaxislink::Int=0,
    flags::ImPlotFlags_=ImPlotFlags_None,
    x_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y2_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None,
    y3_flags::ImPlotAxisFlags_=ImPlotAxisFlags_None)

    plotid = getid(title_id)
    plotinfo = getplotinfo(plotid)

    if xaxislink > 0
        linkxaxis!(plotinfo, xaxislink)
    end

    if changedlastframe(plotinfo.PlotLimits) && xaxislink > 0
        # linked axis may not pull changes until next frame, so let's force a frame refresh
        touch!()
    end 

    sizev2 = ImVec2(convert(Float32, size[1]), convert(Float32, size[2]))

    if LibCImPlot.BeginPlot(title_id, emptytonull(x_label), emptytonull(y_label), sizev2, flags, x_flags, y_flags, y2_flags, y3_flags)
        plotinfo.PlotLimits[] = LibCImPlot.GetPlotLimits()

        inner(plotinfo)

        LibCImPlot.EndPlot()
    end

    plotid
end