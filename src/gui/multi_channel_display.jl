

#=
Plotting multi channel spike display
=#

draw_spike16(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,4,4,16)

draw_spike32(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,6,6,32)

draw_spike64(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,6,11,64)

function draw_spike_n(rhd::RHD2000,han::Gui_Handles,n_col,n_row,num_chan)
    
    k_in=num_chan*(han.num16)-num_chan+1

    if (k_in+num_chan-1)>size(rhd.v,2)
        num_chan=(size(rhd.v,2)-k_in+1)
    end

    num_plot =n_col*n_row
    
    maxid=find_max_id(rhd,han,k_in,num_chan)
    ctx=getgc(han.c)
    xwidth=width(ctx)
    myheight=height(ctx)
    if num_plot<64
      yheight=myheight-300
    else
      yheight=myheight
    end

    scale(ctx,xwidth/(han.wave_points/2*n_col),1)

    #subsequent IDs
    @inbounds for thisid=1:maxid
	for chan=k_in:(k_in+num_chan-1)
	    if han.enabled[chan]
	        for g=1:rhd.nums[chan]
                    if (rhd.buf[g,chan].inds.start>0)&(rhd.buf[g,chan].inds.stop<size(rhd.v,1))
                        if rhd.buf[g,chan].id==thisid

                            #Gain and offset for channel
                            s=han.scale[chan,2]
                            o=han.offset[chan]

                            #x and y position for channel location
			    startx=div(rem(chan-1,num_plot),n_row)*han.wave_points/2+1
			    starty=yheight/n_row*(rem(rem(chan-1,num_plot),n_row))+yheight/n_row/2

                            #Max and min extents for line to stay within bounding box
                            ymax=starty+yheight/n_row/2
			    ymin=starty-yheight/n_row/2

                            y=(rhd.v[rhd.buf[g,chan].inds.start,chan]-o)*s+starty
			    
			    if (y<ymin)
                               y=ymin
                            elseif (y>ymax)
                               y=ymax
                            end
                            
                            move_to(ctx,startx,y)
                            for kk=rhd.buf[g,chan].inds.start+2:2:rhd.buf[g,chan].inds.stop
                                y=(rhd.v[kk,chan]-o)*s+starty
                                if (y<ymin)
                                   y=ymin
                                elseif (y>ymax)
                                   y=ymax
                                end
                                line_to(ctx,startx,y)
                                startx+=1
                            end
                        end
                    end        
                end
	    end
            if chan>length(han.enabled)
                break
            end
	end
	set_line_width(ctx,0.25);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end
    
    identity_matrix(ctx)
    nothing
end

function find_max_id(rhd::RHD2000,han::Gui_Handles,k,num)

    maxid=1
    
    for i=k:(k+num-1)
        if han.enabled[i]
            for g=1:rhd.nums[i]
                if rhd.buf[g,i].id>maxid
                    maxid=rhd.buf[g,i].id
                end
            end
        end
    end
    maxid
end

#=
Prepare multi channel display
=#

function draw_multi_chan(ctx::Cairo.CairoContext,han::Gui_Handles,k,n_row,n_col,chan_num)

    mywidth=width(ctx)

    if chan_num<64
        myheight=height(ctx)-300.0
    else
        myheight=height(ctx)
    end
    
    xbounds=get_bounds(mywidth,n_col+1)
    ybounds=get_bounds(myheight,n_row+1)
    
    for x in xbounds
        line(ctx,x,x,1,myheight)
    end
    for y in ybounds
        line(ctx,1,mywidth,y,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    for x=1:n_col
        for y=1:n_row
            if k<=length(han.enabled)
                move_to(ctx,xbounds[x]+10.0,ybounds[y]+10.0)
                if han.enabled[k] 
                    show_text(ctx,string(k))
                else
                    show_text(ctx,string(k,"-DISABLED"))
                end
            end
            k+=1
        end
    end
    (x1_f,x2_f,y1_f,y2_f)=get_multi_dims(han,n_col,n_row,chan_num,han.num)
    draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    nothing
end

prepare_16(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,16*han.num16-15,4,4,16)

prepare_32(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,32*han.num16-31,6,6,32)

prepare_64(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,64*han.num16-63,11,6,64)
