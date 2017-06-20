
function update_ref(rhd::RHD2000,han::Gui_Handles)

    selmodel_l=Gtk.GAccessor.selection(han.ref_tv1)
    selmodel_r=Gtk.GAccessor.selection(han.ref_tv2)
    
    for i=1:size(rhd.v,2)

        myref=rhd.refs[i]

        if myref!=0

            select!(selmodel_l,Gtk.iter_from_index(han.ref_list1,myref))
            select!(selmodel_r,Gtk.iter_from_index(han.ref_list2,i))         
        end
    end
    nothing
end

#=
Callbacks for reference channel selection
=#

function ref_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.ref_win,true)
    nothing
end

function ref_b1_cb(widget::Ptr, user_data::Tuple{Gui_Handles})

    han, = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_tv1)
    selectall!(selmodel)

    nothing
end

function ref_b2_cb(widget::Ptr, user_data::Tuple{Gui_Handles})

    han, = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_tv2)
    selectall!(selmodel)

    nothing
end

function ref_b3_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    #Left
    selmodel=Gtk.GAccessor.selection(han.ref_tv1)
    myref=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.ref_list1), Gtk.selected(selmodel)))+1
    
    #Right
    for i=1:size(rhd.v,2)
        if is_selected(han.ref_list2,han.ref_tv2,i-1)
            if i==myref
                rhd.refs[i]=0
            else
                rhd.refs[i]=myref
            end
        end
    end

    f=open(string(rhd.save.backup,"ref.bin"),"w")
    write(f,rhd.refs)
    close(f)

    nothing
end
