

#=
Convert canvas coordinates to voltage vs time coordinates
=#
function coordinate_transform(han::Gui_Handles,event)
    (x1,x2,y1,y2)=coordinate_transform(han,han.mi[1],han.mi[2],event.x,event.y)
end

function coordinate_transform(han::Gui_Handles,xi1::Float64,yi1::Float64,xi2::Float64,yi2::Float64)
    
    ctx=han.ctx2

    myx=[1.0;collect(2:(han.wave_points-1)).*(han.w2/han.wave_points)]
    x1=indmin(abs(myx-xi1))
    x2=indmin(abs(myx-xi2))
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    y1=(yi1-han.h2/2+o)/s
    y2=(yi2-han.h2/2+o)/s
    
    #ensure that left most point is first
    if x1>x2
        x=x1
        x1=x2
        x2=x
        y=y1
        y1=y2
        y2=y
    end
    (x1,x2,y1,y2)
end

#=
Rubber Band functions adopted from GtkUtilities.jl package by Tim Holy 2015
=#

function rubberband_start(han::Gui_Handles, x, y, button_num=1)

    han.rb = RubberBand(Vec2(x,y), Vec2(x,y), Vec2(x,y), [Vec2(x,y)],false, 2)
    han.selected=falses(500)
    han.plotted=falses(500)

    if button_num==1
        push!((han.c2.mouse, :button1motion),  (c, event) -> rubberband_move(han,event.x, event.y))
        push!((han.c2.mouse, :motion), Gtk.default_mouse_cb)
        push!((han.c2.mouse, :button1release), (c, event) -> rubberband_stop(han,event.x, event.y,button_num))
    elseif button_num==3
        push!((han.c2.mouse, :motion),  (c, event) -> rubberband_move(han,event.x, event.y))
        push!((han.c2.mouse, :button3release), (c, event) -> rubberband_stop(han,event.x, event.y,button_num))
    end
    han.rb_active=true
    nothing
end

function rubberband_move(han::Gui_Handles, x, y)
    
    han.rb.moved = true
    han.rb.pos2 = Vec2(x ,y)
    nothing
end

function rubberband_stop(han::Gui_Handles, x, y,button_num)

    if button_num==1
        pop!((han.c2.mouse, :button1motion))
        pop!((han.c2.mouse, :motion))
        pop!((han.c2.mouse, :button1release))
    elseif button_num==3
        pop!((han.c2.mouse, :motion))
        pop!((han.c2.mouse, :button3release))
    end
        
    han.rb.moved = false
    han.rb_active=false
    clear_rb(han)
    nothing
end

function draw_rb(han::Gui_Handles)

    if han.rb.moved

        ctx = han.ctx2
        clear_rb(han)

        line(ctx,han.rb.pos0.x,han.rb.pos2.x,han.rb.pos0.y,han.rb.pos2.y)
        set_line_width(ctx,1.0)
        set_source_rgb(ctx,1.0,1.0,1.0)
        stroke(ctx)   

        #Find selected waveforms and plot
        if (han.clus>0)&((han.buf_count>0)&(han.pause))
            get_selected_waveforms(han,han.spike_buf)
            plot_selected_waveforms(han,han.spike_buf)
        end
        han.rb.pos1=han.rb.pos2 
    end
    
    nothing
end

function clear_rb(han::Gui_Handles)

    line(han.ctx2,han.rb.pos0.x,han.rb.pos1.x,han.rb.pos0.y,han.rb.pos1.y)
    set_line_width(han.ctx2,2.0)
    set_source(han.ctx2,han.ctx2s)
    stroke(han.ctx2)
    
    nothing
end

#=
Find waveforms selected by rubberband and assign to mask
=#
function generate_mask{T}(input::Array{T,2},mask,count,x1,y1,x2,y2)

    #Bounds check
    x1 = x1 < 2 ? 2 : x1
    x2 = x2 > size(input,2)-2 ? size(input,2)-2 : x2 
    
    for i=1:count
        for j=(x1-1):(x2+1)
            if SpikeSorting.intersect(x1,x2,j,j+1,y1,y2,input[j,i],input[j+1,i])
                mask[i]=false
                break
            end
        end
    end
    
    nothing
end

#=
Find waveforms 
=#
function get_selected_waveforms{T<:Real}(han::Gui_Handles,input::Array{T,2})

    (x1,x2,y1,y2)=coordinate_transform(han,han.rb.pos0.x,han.rb.pos0.y,han.rb.pos2.x,han.rb.pos2.y)

    if x1<3
        x1=2
    end
    if x2>(size(input,1)-3)
        x2=size(input,1)-3
    end
    
    for i=1:han.buf_count
        intersected=false
        if han.buf_mask[i]
            for j=(x1-1):(x2+1)
                if (SpikeSorting.intersect(x1,x2,j,j+1,y1,y2,input[j,i],input[j+1,i]))
                    intersected=true
                    han.selected[i]=true
                    break
                end
            end
            if (han.plotted[i])&(!intersected)
                han.selected[i]=false
                break
            end
        end
    end
    
    nothing
end

#=
Callback for how mouse interacts with canvas
=#
function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data
    event = unsafe_load(param_tuple)

    han.click_button=event.button
    
    if event.button == 1 #left click captures window
        han.mi=(event.x,event.y)
        rubberband_start(han,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
        if !han.pause
            clear_c2(han.c2,han.spike)
            han.ctx2=getgc(han.c2)
            han.ctx2s=copy(han.ctx2)
            han.buf_ind=1
            han.buf_count=1
            if han.sort_cb
                draw_templates(han)
            end
        else
            han.mi=(event.x,event.y)
            rubberband_start(han,event.x,event.y,3)
        end
    end
    nothing
end
