mutable struct Tracker
    Enabled::Bool
    LastChangedOn::Int
    
    Tracker() = new(false, -1)
end

const tracker = Tracker()

mutable struct Tracked{A}
    Value::A
    ChangedOn::Int

    Tracked{A}() where A = (x = new{A}(); x.ChangedOn = -1; x)
    Tracked(value::A) where A = new{A}(value, -1)    
end
  
function touch!(tracked::Tracked)
    if tracker.Enabled
        framecount = CImGui.GetFrameCount()
        tracked.ChangedOn = framecount
        tracker.LastChangedOn = framecount
    end
end

Base.getindex(tracked::Tracked) = tracked.Value

# only actually set it if different
function Base.setindex!(tracked::Tracked, value)
    if tracked.Value != value
        tracked.Value = value
        touch!(tracked)
    end
end

enabletracking!() = tracker.Enabled = true
disabletracking!() = tracker.Enabled = false
touch!() = tracker.LastChangedOn = CImGui.GetFrameCount()
anychangedthisframe() = tracker.Enabled && tracker.LastChangedOn == CImGui.GetFrameCount()
changedthisframe(tracked::Tracked) = tracked.ChangedOn == CImGui.GetFrameCount()
changedlastframe(tracked::Tracked) = CImGui.GetFrameCount() - tracked.ChangedOn == 1
changedinframes(tracked::Tracked, range) = (CImGui.GetFrameCount() - tracked.ChangedOn) in range