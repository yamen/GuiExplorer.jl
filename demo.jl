Pkg.activate(".")

Pkg.develop(url="https://github.com/yamen/CImGui_jll.jl")
Pkg.develop(url="https://github.com/yamen/CImGui.jl")
Pkg.develop(url="https://github.com/yamen/ImPlot.jl")

using CImGui
using ImPlot

include(joinpath(pathof(CImGui), "..", "..", "demo", "demo.jl"))
include(joinpath(pathof(CImGui), "..", "..", "examples", "demo.jl"))
include(joinpath(pathof(ImPlot), "..", "..", "demo", "example_plots.jl"))
Threads.@spawn include(joinpath(pathof(ImPlot), "..", "..", "demo", "demo.jl"))