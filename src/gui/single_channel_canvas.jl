

#=
Convert canvas coordinates to voltage vs time coordinates
=#
function coordinate_transform(han::Gui_Handles,event)
    (x1,x2,y1,y2)=coordinate_transform(han,han.sc.mi[1],han.sc.mi[2],event.x,event.y)
end

function coordinate_transform(han::Gui_Handles,xi1::Float64,yi1::Float64,xi2::Float64,yi2::Float64)
    
    ctx=han.sc.ctx2

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

    han.sc.rb = RubberBand(Vec2(x,y), Vec2(x,y), Vec2(x,y), [Vec2(x,y)],false, 2)
    han.sc.selected=falses(500)
    han.sc.plotted=falses(500)

    if button_num==1
        push!((han.sc.c2.mouse, :button1motion),  (c, event) -> rubberband_move(han,event.x, event.y))
        push!((han.sc.c2.mouse, :motion), Gtk.default_mouse_cb)
        push!((han.sc.c2.mouse, :button1release), (c, event) -> rubberband_stop(han,event.x, event.y,button_num))
    elseif button_num==3
        push!((han.sc.c2.mouse, :motion),  (c, event) -> rubberband_move(han,event.x, event.y))
        push!((han.sc.c2.mouse, :button3release), (c, event) -> rubberband_stop(han,event.x, event.y,button_num))
    end
    han.sc.rb_active=true
    nothing
end

function rubberband_move(han::Gui_Handles, x, y)
    
    han.sc.rb.moved = true
    han.sc.rb.pos2 = Vec2(x ,y)
    nothing
end

function rubberband_stop(han::Gui_Handles, x, y,button_num)

    if button_num==1
        pop!((han.sc.c2.mouse, :button1motion))
        pop!((han.sc.c2.mouse, :motion))
        pop!((han.sc.c2.mouse, :button1release))
    elseif button_num==3
        pop!((han.sc.c2.mouse, :motion))
        pop!((han.sc.c2.mouse, :button3release))
    end
        
    han.sc.rb.moved = false
    han.sc.rb_active=false
    clear_rb(han)
    nothing
end

function draw_rb(han::Gui_Handles)

    if han.sc.rb.moved

        ctx = han.sc.ctx2
        clear_rb(han)

        line(ctx,han.sc.rb.pos0.x,han.sc.rb.pos2.x,han.sc.rb.pos0.y,han.sc.rb.pos2.y)
        set_line_width(ctx,1.0)
        set_source_rgb(ctx,1.0,1.0,1.0)
        stroke(ctx)   

        #Find selected waveforms and plot
        if (han.buf.selected_clus>0)&((han.buf.count>0)&(han.sc.pause))
            get_selected_waveforms(han,han.buf.spikes)
            mycolor=1
            if han.sc.click_button==1
                mycolor=han.buf.selected_clus+1
            elseif han.sc.click_button==3
                mycolor=1
            end
            plot_selected_waveforms(han,han.buf.spikes,mycolor)
        end
        han.sc.rb.pos1=han.sc.rb.pos2 
    end
    
    nothing
end

function clear_rb(han::Gui_Handles)

    line(han.sc.ctx2,han.sc.rb.pos0.x,han.sc.rb.pos1.x,han.sc.rb.pos0.y,han.sc.rb.pos1.y)
    set_line_width(han.sc.ctx2,2.0)
    set_source(han.sc.ctx2,han.sc.ctx2s)
    stroke(han.sc.ctx2)
    
    nothing
end

#=
Find waveforms that cross line defined by (x1,y1),(x2,y2)
=#
function find_intersected_waveforms{T}(input::Array{T,2},mask,count,x1,y1,x2,y2)

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
Find which of the intersected waveforms are in a different cluster and if that difference has already been plotted
=#
function get_selected_waveforms{T<:Real}(han::Gui_Handles,input::Array{T,2})

    (x1,x2,y1,y2)=coordinate_transform(han,han.sc.rb.pos0.x,han.sc.rb.pos0.y,han.sc.rb.pos2.x,han.sc.rb.pos2.y)

    intersection = trues(han.buf.ind)
    find_intersected_waveforms(han.buf.spikes,intersection,han.buf.ind,x1,y1,x2,y2)

    for i=1:han.buf.ind
        if han.buf.mask[i]
            if !intersection[i]
                han.sc.selected[i]=true
            end
            if (han.sc.plotted[i])&(intersection[i])
                han.sc.selected[i]=false
            end
        end
    end

    nothing
end

#=
PLOTTING METHODS

In the main single channel, we need to be able to plot under multiple conditions

-Online plotting of new spikes

-Replot spikes in paused display
--Replot all spikes in display
---After right-click rubber band to mask waveform
---After left-click rubber band creates new cluster
--Replot spikes that have changed since last event
---Using slider to adjust template bounds

-Incrementally plot spikes while rubber band is in use in paused display
--Should plot spikes that were just selected in selected color
--Should restore spikes that are no longer selected in previous color

=#

#=
Online plotting of new spikes in non-paused display
=#
function draw_spike(rhd::RHD2000,han::Gui_Handles)

    spike_num=han.spike
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    reads=han.draws

    ctx=copy(han.sc.ctx2s)
    paint_with_alpha(ctx,0.0)

    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)
    
    for i=1:rhd.nums[spike_num]

        kk=rhd.buf[i,spike_num].inds.start
        k_end=rhd.buf[i,spike_num].inds.stop
        if (kk>0) & (k_end<size(rhd.v,1))
        
            move_to(ctx,1,rhd.v[kk,spike_num]-o)
            
            for k=2:han.wave_points
                y = rhd.v[kk+k-1,spike_num]-o
                line_to(ctx,k,y)
            end
			
	    set_line_width(ctx,0.5);
	    @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	    stroke(ctx)

            #Add spike to buffer
            if han.buf.count > 0
                mycount=1
                for k=1:han.wave_points
                    han.buf.spikes[mycount,han.buf.ind] = rhd.v[kk+k-1,spike_num]
                    mycount+=1
                end
                han.buf.clus[han.buf.ind] = rhd.buf[i,spike_num].id-1
                han.buf.count+=1
                han.buf.ind+=1
                if han.buf.count>500
                    han.buf.count=500
                end
                if han.buf.ind>500
                    han.buf.ind=1
                end
            end

            update_isi(rhd,han,i)
        end
    end

    identity_matrix(ctx)

    set_source(han.sc.ctx2s,ctx)
    mask_surface(han.sc.ctx2s,ctx,0.0,0.0)
    fill(han.sc.ctx2s)

    set_source(han.sc.ctx2,ctx)
    mask_surface(han.sc.ctx2,ctx,0.0,0.0)
    fill(han.sc.ctx2)
    
    nothing
end

function mask_surface(ctx,s,x,y)
    ccall((:cairo_mask_surface,Cairo._jl_libcairo),Void,(Ptr{Void},Ptr{Void},Float64,Float64),ctx.ptr,s.surface.ptr,x,y)
end

#=
Redraw all spikes shown in paused view
=#
function replot_all_spikes(han::Gui_Handles)

    clear_c2(han.sc.c2,han.spike)
    han.sc.ctx2=getgc(han.sc.c2)
    han.sc.ctx2s=copy(han.sc.ctx2)

    ctx=han.sc.ctx2s
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]

    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)

    for i=1:(han.total_clus[han.spike]+1)
        for j=1:han.buf.ind
            if (han.buf.clus[j]==(i-1))&(han.buf.mask[j])
                move_to(ctx,1,(han.buf.spikes[1,j]-o))
                for jj=2:size(han.buf.spikes,1)
                    line_to(ctx,jj,han.buf.spikes[jj,j]-o)
                end
            end
        end
        set_line_width(ctx,0.5)
        select_color(ctx,i)
        stroke(ctx)
    end
    identity_matrix(ctx)
    set_source(han.sc.ctx2,ctx)
    mask_surface(han.sc.ctx2,ctx,0.0,0.0)
    fill(han.sc.ctx2)
    reveal(han.sc.c2)
    nothing
end

#=
Plot waveforms in incremental way
-Rubberband

Selected - true if waveform is captured by incremental capture
Plotted - true if waveform has been replotted in new color since start of incremental capture
=#
function plot_selected_waveforms{T<:Real}(han::Gui_Handles,input::Array{T,2},mycolor)

    ctx=han.sc.ctx2
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]

    set_line_width(ctx,2.0)
    set_source(ctx,han.sc.ctx2s)
    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)

    #=
    Reset waveforms that have changed since the start but are
    no longer selected
    =#
    for j=1:han.buf.count
        if (!han.sc.selected[j])&(han.sc.plotted[j])
            move_to(ctx,1,(input[1,j]-o))
            for jj=2:size(input,1)
                line_to(ctx,jj,input[jj,j]-o)
            end
            han.sc.plotted[j]=false
        end
    end
    stroke(ctx)

    #=
    Plot selected waveforms in new color that have not 
    yet been plotting in new color
    =#
    for i=1:han.buf.count
        if (han.sc.selected[i])&(!han.sc.plotted[i])
            move_to(ctx,1,(input[1,i]-o))
            for jj=2:size(input,1)
                line_to(ctx,jj,input[jj,i]-o)
            end
            han.sc.plotted[i]=true
        end
    end
    set_line_width(ctx,0.5)
    select_color(ctx,mycolor)
    stroke(ctx)

    identity_matrix(ctx)
    nothing
end


#=
Callback for how mouse interacts with canvas
=#
function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data
    event = unsafe_load(param_tuple)

    han.sc.click_button=event.button
    
    if event.button == 1 #left click captures window
        han.sc.mi=(event.x,event.y)
        rubberband_start(han,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
        if !han.sc.pause
            clear_c2(han.sc.c2,han.spike)
            han.sc.ctx2=getgc(han.sc.c2)
            han.sc.ctx2s=copy(han.sc.ctx2)
            han.buf.ind=1
            han.buf.count=1
            if han.sort_cb
                draw_templates(han)
            end
        else
            han.sc.mi=(event.x,event.y)
            rubberband_start(han,event.x,event.y,3)
        end
    end
    nothing
end
