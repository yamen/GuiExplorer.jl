mutable struct GuiContext{S,T}
    state::S
    channel::Channel{T}
end

GuiContext{T}(state::S, buffer::Int) where {T,S} = GuiContext(state, Channel{T}(buffer))
GuiContext{T}(state::S) where {T,S} = GuiContext{T}(state, 100)

function run(context::GuiContext{S,T}; width=1920, height=1200, title::AbstractString="Demo", hotloading=true, waitevents=0.1) where {S,T}
    function renderer()
        # just take 1 message, can change to a 'while' loop if more appropriate
        if isready(context.channel) 
            value = take!(context.channel)
            update!(context, value)
        end

        # return true for 'draw immediately' and false for 'wait for input event or timeout'
        buildui(context) || isready(context.channel)
    end

    empty!(PlotInfoCache)

    t = Renderer.render_thread(renderer; width, height, title, hotloading, waitevents)

    enabletracking!()
    bind(context.channel, t)

    return t
end

function createandrun(initialstate::S, messagetype::Type{T}; width=1920, height=1200, title::AbstractString="Demo", hotloading=true, waitevents=0.1) where {S,T}
    context = GuiContext{T}(initialstate)
    
    task = run(context; width, height, title, hotloading, waitevents)

    return context, task
end

dispatch!(context::GuiContext{S,T}, message::T) where {S,T} = put!(context.channel, message)
(context::GuiContext{S,T})(message::T) where {S,T} = put!(context.channel, message)
buildui(context) = false
update!(context, message) = ()