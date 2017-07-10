

function table_col_cb(widget::Ptr, path,new_text,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han,rhd,col = user_data

    selmodel = Gtk.GAccessor.selection(han.table_widgets.tv)

    iter=Gtk.selected(selmodel)

    num=parse(Int64,unsafe_string(new_text))

    setindex!(han.table_widgets.list,num,iter,col)

    nothing
end

function table_en_cb(widget::Ptr,path,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    num=parse(Int64,unsafe_string(path))+1

    val=getindex(han.table_widgets.list,num,5)

    setindex!(han.table_widgets.list,!val,num,5)
    
    nothing
end

function table_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    for i=1:size(rhd.v,2)

        setindex!(han.table_widgets.list,round(Int64,han.scale[i,1]*-1000),i,2)
        setindex!(han.table_widgets.list,han.sc.thres,i,3)
        setindex!(han.table_widgets.list,rhd.refs[i],i,4)
        setindex!(han.table_widgets.list,han.enabled[i],i,5)

    end

    visible(han.table_widgets.win,true)
    nothing
end
