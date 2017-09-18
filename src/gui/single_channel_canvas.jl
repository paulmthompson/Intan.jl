
#=
Online plotting of new spikes in non-paused display
=#
function draw_spike(rhd::RHD2000,han::Gui_Handles)

    spike_num=han.spike
    s=han.sc.s
    o=han.sc.o
    reads=han.draws

    ctx=copy(han.sc.ctx2s)
    paint_with_alpha(ctx,0.0)

    Cairo.translate(ctx,0.0,han.sc.h2/2)
    scale(ctx,han.sc.w2/han.wave_points,s)
    
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

    SpikeSorting.clear_c2(han.sc.c2,han.spike)
    han.sc.ctx2=getgc(han.sc.c2)
    han.sc.ctx2s=copy(han.sc.ctx2)

    ctx=han.sc.ctx2s
    s=han.sc.s
    o=han.sc.o

    Cairo.translate(ctx,0.0,han.sc.h2/2)
    scale(ctx,han.sc.w2/han.sc.wave_points,s)

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
Callback for how mouse interacts with canvas
=#
function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data
    event = unsafe_load(param_tuple)

    han.sc.click_button=event.button
    
    if event.button == 1 #left click captures window
        han.sc.mi=(event.x,event.y)
        if han.sc.pause_state==1
            SpikeSorting.rubberband_start(han.sc,event.x,event.y)
        elseif han.sc.pause_state == 2
            if han.sc.pause
                SpikeSorting.draw_start(han.sc,event.x,event.y,han.temp)
            end
        end
    elseif event.button == 3 #right click refreshes window
        if !han.sc.pause
            SpikeSorting.clear_c2(han.sc.c2,han.spike)
            han.sc.ctx2=getgc(han.sc.c2)
            han.sc.ctx2s=copy(han.sc.ctx2)
            han.buf.ind=1
            han.buf.count=1
            if han.sort_cb
                draw_templates(han)
            end
        else
            han.sc.mi=(event.x,event.y)
            if han.sc.pause_state==1
                SpikeSorting.rubberband_start(han.sc,event.x,event.y,3)
            elseif han.sc.pause_state == 2

            end
        end
    end
    nothing
end
