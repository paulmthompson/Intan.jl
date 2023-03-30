
function _make_table_gui()

    #Table of Values Popup
    table_grid=Grid()

    table_list=ListStore(Int32,Int32,Int32,Int32,Bool)
    for i=1:0
        push!(table_list,(i,125,0,0,true))
    end

    table_tv=TreeView(TreeModel(table_list))
    table_rtext1=CellRendererText()
    table_rtext2=CellRendererText()
    set_gtk_property!(table_rtext2, :editable, true)
    table_rtext3=CellRendererText()
    set_gtk_property!(table_rtext3, :editable, true)
    table_rtext4=CellRendererText()
    set_gtk_property!(table_rtext4, :editable, true)
    table_rtog=CellRendererToggle()
    set_gtk_property!(table_rtog, :activatable, true)

    table_c1 = TreeViewColumn("Channel",table_rtext1,Dict([("text",0)]))
    table_c2 = TreeViewColumn("Gain", table_rtext2, Dict([("text",1)]))
    table_c3 = TreeViewColumn("Threshold", table_rtext3, Dict([("text",2)]))
    table_c4 = TreeViewColumn("Reference", table_rtext4, Dict([("text",3)]))
    table_c5 = TreeViewColumn("Enabled",table_rtog,Dict([("active",4)]))

    push!(table_tv,table_c1)
    push!(table_tv,table_c2)
    push!(table_tv,table_c3)
    push!(table_tv,table_c4)
    push!(table_tv,table_c5)

    table_scroll=ScrolledWindow()
    Gtk.GAccessor.min_content_height(table_scroll,500)
    Gtk.GAccessor.min_content_width(table_scroll,500)
    push!(table_scroll,table_tv)

    table_grid[1,1]=table_scroll

    table_win=Window(table_grid)
    set_gtk_property!(table_win, :title, "Parameter List")

    Gtk.showall(table_win)
    visible(table_win,false)

    table_widgets=Table_Widgets(table_win,table_tv,table_list,table_rtext2,table_rtext3,table_rtext4,table_rtog)
end

function add_parameter_callbacks(w,handles,r,fpga)

    signal_connect(w.win, :delete_event) do widget, event
        visible(w.win,false)
        true
    end

    signal_connect(table_col_cb, w.gain_text,"edited",Nothing,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,2))
    signal_connect(table_col_cb, w.thres_text,"edited",Nothing,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,3))
    signal_connect(table_col_cb, w.ref_text,"edited",Nothing,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,4))
    signal_connect(table_en_cb, w.enabled_toggle, "toggled",Nothing,(Ptr{UInt8},),false,(handles,r))

    nothing
end

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

        setindex!(han.table_widgets.list,round(Int64,han.scale[i,1]*-1000),i,digits=2)
        setindex!(han.table_widgets.list,han.sc.thres,i,3)
        setindex!(han.table_widgets.list,rhd.refs[i],i,4)
        setindex!(han.table_widgets.list,han.enabled[i],i,5)

    end

    visible(han.table_widgets.win,true)
    nothing
end
