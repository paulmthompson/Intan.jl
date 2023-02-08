
function _make_save_gui()

    save_grid=Grid()

    save_entry=Entry()
    #Gtk.GAccessor.text(save_entry,r.save.folder)
    save_grid[1,1]=Label("Save Folder: ")
    save_grid[2,1]=save_entry

    save_check_volt=CheckButton("Analog Voltage")
    save_grid[1,2]=save_check_volt

    save_check_lfp=CheckButton("LFP")
    save_grid[1,3]=save_check_lfp

    save_check_ttlin=CheckButton("TTL input")
    save_grid[1,4]=save_check_ttlin

    save_check_ts=CheckButton("Spike Time Stamps")
    save_grid[1,5]=save_check_ts

    save_check_adc=CheckButton("ADC Input")
    save_grid[1,6]=save_check_adc

    save_pref_win=Window(save_grid)
    setproperty!(save_pref_win, :title, "Saving Preferences")

    Gtk.showall(save_pref_win)
    visible(save_pref_win,false)

    save_widgets=Save_Widgets(save_pref_win,save_check_volt,save_check_lfp,save_check_ttlin,save_check_ts,save_check_adc,save_entry)
end

function add_save_callbacks(w,handles,r,fpga)

    #This should be a longer callback where the save preference checkboxes are loaded
    #automatically
    signal_connect(w.win, :delete_event) do widget, event
        visible(w.win, false)
        true
    end
    signal_connect(save_volt_cb,w.volt,"clicked",Nothing,(),false,(handles,r))
    signal_connect(save_lfp_cb,w.lfp,"clicked",Nothing,(),false,(handles,r))
    signal_connect(save_ttlin_cb,w.ttlin,"clicked",Nothing,(),false,(handles,r))
    signal_connect(save_ts_cb,w.ts,"clicked",Nothing,(),false,(handles,r))
    signal_connect(save_entry_cb,w.input,"activate",Nothing,(),false,(handles,r))
    signal_connect(save_adc_cb,w.adc,"clicked",Nothing,(),false,(handles,r))

    nothing
end


function saving_pref_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.save_widgets.win,true)
    nothing
end

function save_volt_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han,rhd = user_data

    rhd.save.save_full=getproperty(han.save_widgets.volt,:active,Bool)

    if rhd.save.save_full
        prepare_v_header(rhd)
    end

    nothing
end

function save_lfp_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    rhd.save.lfp_s=getproperty(han.save_widgets.lfp,:active,Bool)

    if rhd.save.lfp_s
        prepare_lfp_header(rhd)
    end

    nothing
end

function save_ttlin_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han,rhd = user_data
    rhd.save.ttl_s=getproperty(han.save_widgets.ttlin,:active,Bool)

    if rhd.save.ttl_s
        prepare_ttl_header(rhd)
    end

    nothing
end

function save_ts_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han,rhd = user_data
    rhd.save.ts_s = getproperty(han.save_widgets.ts,:active,Bool)

    if rhd.save.ts_s
        prepare_stamp_header(rhd)
    end

    nothing
end

function save_adc_cb(w::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han,rhd=user_data
    rhd.save.adc_s = getproperty(han.save_widgets.adc,:active,Bool)

    if rhd.save.adc_s
        prepare_adc_header(rhd)
    end

    nothing
end

function save_entry_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    base_path = getproperty(han.save_widgets.input,:text,String)
    backup_path = string(base_path,"/.backup/")
    rhd.save.folder=base_path
    rhd.save.backup=backup_path
    rhd.save.v=string(base_path,"/v.bin")
    rhd.save.ts=string(base_path,"/ts.bin")
    rhd.save.ttl=string(base_path,"/ttl.bin")
    rhd.save.ttl_out=string(base_path,"/ttl_out.bin")
    rhd.save.lfp=string(base_path,"/lfp.bin")
    rhd.save.adc=string(base_path,"/adc.bin")

    prepare_save_folder(rhd)

    if rhd.save.save_full
        prepare_v_header(rhd)
    end
    if rhd.save.ts_s
        prepare_stamp_header(rhd)
    end
    if rhd.save.adc_s
        prepare_adc_header(rhd)
    end
    if rhd.save.ttl_s
        prepare_ttl_header(rhd) #TTL in
        prepare_ttl_header(rhd,rhd.save.ttl_out) #TTl out
    end
    if rhd.save.lfp_s
        prepare_lfp_header(rhd)
    end

    nothing
end

#Prepare saving headers
function prepare_save_folder(r)
    mkdir(r.save.folder)
    mkdir(r.save.backup)
    mkdir(string(r.save.backup,"thres"))
    mkdir(string(r.save.backup,"gain"))
    mkdir(string(r.save.backup,"cluster"))

    f=open(string(r.save.backup,"backup.bin"),"w")
        write(f,1)
    close(f)
end
