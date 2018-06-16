

#=
Buttons on right side determine what is displayed on canvas1
=#

function rb1_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if han.c_right_top != event_id
        han.c_right_top=event_id

        if event_id==3
            if han.c_right_bottom != 5
                setproperty!(han.rb2[5],:active,true)
            end
        elseif event_id==4
            if han.c_right_bottom != 6
                setproperty!(han.rb2[6],:active,true)
            end
        else
            if (han.c_right_bottom == 5)|(han.c_right_bottom == 6)
                setproperty!(han.rb2[8],:active,true)
            end
        end
    end

    if han.c_right_top == 1
	set_slider(han,16)
    elseif han.c_right_top == 2
	set_slider(han,32)
    elseif (han.c_right_top == 3)|(han.c_right_top == 4)
	set_slider(han,64)
    end
    
    clear_c(han)
    nothing
end

function rb2_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if han.c_right_bottom != event_id
        han.c_right_bottom=event_id

        if event_id==5
            if han.c_right_top!=3
                setproperty!(han.rb1[3],:active,true)
            end
        elseif event_id==6
            if han.c_right_top != 4
                setproperty!(han.rb1[4],:active,true)
            end
        elseif event_id == 7
            ctx=Gtk.getgc(han.c)
            han.c.back.ptr = CairoRGBSurface(width(ctx),height(ctx)).ptr
            han.c.backcc = CairoContext(han.c.back)
        else
            if (han.c_right_top == 3)|(han.c_right_top == 4)
                setproperty!(han.rb1[1],:active,true)
            end
        end
    end

    clear_c(han)
    nothing
end

function set_slider(han::Gui_Handles,chan_num::Int64)
    han.num16=div(han.spike-1,chan_num)+1
    han.num=rem(han.spike-1,chan_num)+1
    han.chan_per_display=chan_num
    if han.num16*chan_num>length(han.enabled)
        setproperty!(han.adj2,:upper,han.num16*chan_num-length(han.enabled))
        setproperty!(han.adj,:upper,div(length(han.enabled),chan_num)+1)
    else
        setproperty!(han.adj2,:upper,chan_num)
        setproperty!(han.adj,:upper,div(length(han.enabled),chan_num))
    end
    setproperty!(han.adj2, :value, han.num)
    setproperty!(han.adj, :value, han.num16)  
    nothing
end
