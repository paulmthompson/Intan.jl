
#=
Treeview Functions
=#

#=
Callback
=#
function unit_select_cb(w::Ptr,p1,p2,user_data::Tuple{Gui_Handles})

    han, = user_data
    select_unit(han)
end

function select_unit(han::Gui_Handles)
    clus=get_cluster_id(han)

    old_clus=han.buf.selected_clus

    han.buf.selected_clus=clus
    if clus>0
        mytol=han.sc.temp.tol[clus]
        setproperty!(han.adj_sort, :value, mytol)
    end

    ctx=Gtk.getgc(han.sc.c3)

    if old_clus>0
        (x1_i,x2_i,y1_i,y2_i)=get_template_dims(han,old_clus)
        draw_box(x1_i,y1_i,x2_i,y2_i,(0.0,0.0,0.0),2.0,ctx)
        draw_box(x1_i,y1_i,x2_i,y2_i,(1.0,1.0,1.0),1.0,ctx)
    end

    if han.buf.selected_clus>0
        (x1_f,x2_f,y1_f,y2_f)=get_template_dims(han,han.buf.selected_clus)
        draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    end

    nothing
end

function get_cluster_id(han::Gui_Handles)
    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    iter=Gtk.selected(selmodel)

    myind=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.sort_list), iter))
end

function update_treeview(han::Gui_Handles)

    for i=length(han.sort_list):-1:2
        deleteat!(han.sort_list,i)
    end

    for i=1:han.sc.total_clus
        push!(han.sort_list,(i,))
    end

    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    select!(selmodel, Gtk.iter_from_index(han.sort_list,1))

    nothing
end

function is_selected(store,tv,ind)
    iter=Gtk.iter_from_string_index(store,string(ind))
    selection=Gtk.GAccessor.selection(tv)
    ccall((:gtk_tree_selection_iter_is_selected, Gtk.libgtk),Bool,
    (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}),selection, Gtk.mutable(iter))
end
