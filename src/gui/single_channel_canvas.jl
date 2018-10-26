
#=
Online plotting of new spikes in non-paused display
=#
function draw_spike(rhd::RHD2000,han::Gui_Handles)

    spike_num=han.sc.spike
    s=han.sc.s
    o=han.sc.o
    reads=han.draws

    ctx=copy(han.sc.ctx2s)
    paint_with_alpha(ctx,0.0)

    Cairo.translate(ctx,0.0,han.sc.h2/2)
    Cairo.scale(ctx,han.sc.w2/han.wave_points,s)

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
    SpikeSorting.mask_surface(han.sc.ctx2s,ctx,0.0,0.0)
    fill(han.sc.ctx2s)

    set_source(han.sc.ctx2,ctx)
    SpikeSorting.mask_surface(han.sc.ctx2,ctx,0.0,0.0)
    fill(han.sc.ctx2)

    nothing
end
