module Renderer

using CImGui
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using ImPlot

function __init__()
    @static if Sys.isapple()
        # OpenGL 3.2 + GLSL 150
        global glsl_version = 150
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
    else
        # OpenGL 3.0 + GLSL 130
        global glsl_version = 130
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
        # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    end
end

error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"

function init_renderer(width, height, title::AbstractString)
    # setup GLFW error callback
    GLFW.SetErrorCallback(error_callback)

    # create window
    window = GLFW.CreateWindow(width, height, title)
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()
    ctxp = ImPlot.CreateContext()
    ImPlot.SetImGuiContext(ctx)

    # setup Dear ImGui style
    CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    # CImGui.StyleColorsLight()

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)

    return window, ctx, ctxp
end

# can pretty easily extend this to take in another function that returns the wait time
# this would allow that function to do the pre-render processing and decide on whether a wait or not is appropriate
# plus can return GLFW.PostEmptyEvent from window creation to use as 'signal immediately' if needed
function renderloop(window, ctx, ctxp, ui=() -> false, hotloading=false, waitevents=0.1)
    nowait = false
    try
        while !GLFW.WindowShouldClose(window)
            # poll events if no waiting desired, otherwise wait
            if nowait 
                GLFW.PollEvents()
            else
                GLFW.WaitEvents(waitevents)
            end
            
            ImGui_ImplOpenGL3_NewFrame()
            ImGui_ImplGlfw_NewFrame()
            CImGui.NewFrame()

            # this returns true if there are more events to process
            nowait = hotloading ? Base.invokelatest(ui) : ui()

            CImGui.Render()
            GLFW.MakeContextCurrent(window)
            display_w, display_h = GLFW.GetFramebufferSize(window)
            glViewport(0, 0, display_w, display_h)
            glClearColor(0.2, 0.2, 0.2, 1)
            glClear(GL_COLOR_BUFFER_BIT)
            ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

            GLFW.MakeContextCurrent(window)
            GLFW.SwapBuffers(window)
            yield()
        end
    catch e
        @error "Error in renderloop!" exception = e
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        ImGui_ImplOpenGL3_Shutdown()
        ImGui_ImplGlfw_Shutdown()
        CImGui.DestroyContext(ctx)
        ImPlot.DestroyContext(ctxp)
        GLFW.DestroyWindow(window)
    end
end

function render_async(ui; width=1280, height=720, title::AbstractString="Demo", hotloading=false, waitevents=0.1)
    window, ctx, ctxp = init_renderer(width, height, title)
    GC.@preserve window ctx begin
        t = @async renderloop(window, ctx, ctxp, ui, hotloading, waitevents)
    end
    return t
end

function render_thread(ui; width=1280, height=720, title::AbstractString="Demo", hotloading=false, waitevents=0.1)
    t = Threads.@spawn begin
        window, ctx, ctxp = init_renderer(width, height, title)
        GC.@preserve window ctx begin
            renderloop(window, ctx, ctxp, ui, hotloading, waitevents)
        end
    end

    return t
end

end # module