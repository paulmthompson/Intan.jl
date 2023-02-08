
function _make_reference_gui()
    ref_grid=Grid()

    ref_list1=ListStore(Int32)
    for i=1:0
        push!(ref_list1,(i,))
    end
    ref_tv1=TreeView(TreeModel(ref_list1))
    ref_r1=CellRendererText()
    ref_c1=TreeViewColumn("New Reference:",ref_r1, Dict([("text",0)]))

    ref_tv1_s=Gtk.GAccessor.selection(ref_tv1)

    push!(ref_tv1,ref_c1)

    ref_scroll1=ScrolledWindow()
    Gtk.GAccessor.min_content_height(ref_scroll1,350)
    Gtk.GAccessor.min_content_width(ref_scroll1,175)
    push!(ref_scroll1,ref_tv1)

    ref_list2=ListStore(Int32)
    for i=1:0
        push!(ref_list2,(i,))
    end
    ref_tv2=TreeView(TreeModel(ref_list2))
    ref_r2=CellRendererText()
    ref_c2=TreeViewColumn("Apply Reference To:",ref_r2, Dict([("text",0)]))

    ref_tv2_s=Gtk.GAccessor.selection(ref_tv2)
    Gtk.GAccessor.mode(ref_tv2_s,Gtk.GConstants.GtkSelectionMode.MULTIPLE)

    push!(ref_tv2,ref_c2)

    ref_scroll2=ScrolledWindow()
    Gtk.GAccessor.min_content_height(ref_scroll2,350)
    Gtk.GAccessor.min_content_width(ref_scroll2,175)
    push!(ref_scroll2,ref_tv2)

    ref_button2=Button("Select All/None")
    ref_button3=Button("Apply")

    ref_grid[1,1]=ref_scroll1
    ref_grid[2,1]=Canvas(50,350)
    ref_grid[3,1]=ref_scroll2
    ref_grid[3,2]=ref_button2
    ref_grid[2,3]=Canvas(50,50)
    ref_grid[3,4]=ref_button3
    ref_win=Window(ref_grid)
    setproperty!(ref_win, :title, "Reference Channel Select")

    Gtk.showall(ref_win)
    visible(ref_win,false)

    ref_widgets = Reference_Widgets(ref_win,ref_tv1,ref_tv2,ref_list1,ref_list2,ref_button2,ref_button3)
end

function add_reference_callbacks(w,handles,r,fpga)

    signal_connect(ref_b2_cb, w.select_button, "clicked",Nothing,(),false,(handles,))
    signal_connect(ref_b3_cb, w.apply_button, "clicked",Nothing,(),false,(handles,r))

    signal_connect(w.win, :delete_event) do widget, event
        visible(w.win, false)
        true
    end
end

function update_ref(rhd::RHD2000,han::Gui_Handles)

    selmodel_l=Gtk.GAccessor.selection(han.ref_widgets.tv1)
    selmodel_r=Gtk.GAccessor.selection(han.ref_widgets.tv2)

    for i=1:size(rhd.v,2)

        myref=rhd.refs[i]

        if myref!=0

            select!(selmodel_l,Gtk.iter_from_index(han.ref_widgets.list1,myref))
            select!(selmodel_r,Gtk.iter_from_index(han.ref_widgets.list2,i))
        end
    end
    nothing
end

#=
Callbacks for reference channel selection
=#

function ref_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.ref_widgets.win,true)
    nothing
end

function ref_b1_cb(widget::Ptr, user_data::Tuple{Gui_Handles})

    han, = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_widgets.tv1)
    selectall!(selmodel)

    nothing
end

function ref_b2_cb(widget::Ptr, user_data::Tuple{Gui_Handles})

    han, = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_widgets.tv2)
    selectall!(selmodel)

    nothing
end

function ref_b3_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    #Left
    selmodel=Gtk.GAccessor.selection(han.ref_widgets.tv1)
    myref=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.ref_widgets.list1), Gtk.selected(selmodel)))+1

    #Right
    for i=1:size(rhd.v,2)
        if is_selected(han.ref_widgets.list2,han.ref_widgets.tv2,i-1)
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
