module Gui

using CImGui
import CImGui:ImVec2
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.LibCImGui
using ImPlot
using ImPlot.LibCImPlot

ImGui = CImGui
export ImPlot, ImGui, ImVec2, GuiContext
export PlotInfo, xmin, xmax, ymin, ymax
export Tracked

include("Renderer.jl")
using .Renderer

include("util.jl")
include("track.jl")
include("imguiwrappers.jl")
include("plot.jl")
include("finplot.jl")
include("debugwindows.jl")
include("run.jl")

end