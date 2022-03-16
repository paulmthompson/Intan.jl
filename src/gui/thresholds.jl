

function _make_thres_gui()

    frame1_3=Frame("Threshold")
    vbox1_3_1=Box(:v)
    push!(frame1_3,vbox1_3_1)

    #sb=SpinButton(-300:300)
    #setproperty!(sb,:value,0)
    sb=Label("0")
    push!(vbox1_3_1,sb)

    button_thres_all = CheckButton()
    add_button_label(button_thres_all,"All Channels")
    Gtk.GAccessor.active(button_thres_all,false)
    push!(vbox1_3_1,button_thres_all)

    button_thres = CheckButton()
    add_button_label(button_thres,"Show")
    Gtk.GAccessor.active(button_thres,false)
    push!(vbox1_3_1,button_thres)

    vbox_slider=Box(:v)
    thres_slider = Scale(true, -300,300,1)
    adj_thres = Adjustment(thres_slider)
    Gtk.GAccessor.value(adj_thres,0)

    c_thres=Canvas(10,200)
    Gtk.GAccessor.vexpand(c_thres,false)

    Gtk.GAccessor.inverted(thres_slider,true)
    Gtk.GAccessor.draw_value(thres_slider,false)

    Gtk.GAccessor.vexpand(thres_slider,true)
    push!(vbox_slider,thres_slider)
    push!(vbox_slider,c_thres)

    thres_widgets=SpikeSorting.Thres_Widgets(sb,thres_slider,adj_thres,button_thres_all,button_thres)

    (thres_widgets,frame1_3,vbox_slider)
end

function add_thres_cb(sc_widgets)

    signal_connect(SpikeSorting.thres_cb,sc_widgets.thres_slider,"value-changed",Void,(),false,(sc_widgets,))
    signal_connect(SpikeSorting.thres_show_cb,sc_widgets.thres_widgets.show,"clicked",Void,(),false,(sc_widgets,))

    nothing
end

#=
Set Threshold for sorting equal to GUI threshold
=#
function thres_changed(han::Gui_Handles,s,fpga,backup)

    mythres=getproperty(han.sc.adj_thres,:value,Int)
    han.sc.thres=mythres

    update_thres(han,s,backup)

    send_thres_to_ic(han,fpga)

    han.sc.thres_changed=false

    nothing
end

#=
Functions used to update Sorting data structure with threshold from slider
=#
function update_thres(han::Gui_Handles,s::Array,backup)
    if (getproperty(han.sc.thres_widgets.all,:active,Bool))|(getproperty(han.sc.gain_widgets.all,:active,Bool))
        @inbounds for i=1:length(s)
            s[i].thres=-1*han.sc.thres/han.scale[i,1]+han.offset[i]
            f=open(string(backup,"thres/",i,".bin"),"w")
            write(f,s[i].thres)
            close(f)
        end
    else
        @inbounds s[han.sc.spike].thres=-1*han.sc.thres/han.sc.s+han.sc.o
        f=open(string(backup,"thres/",han.sc.spike,".bin"),"w")
        write(f,s[han.sc.spike].thres)
        close(f)
    end
end

function update_thres(han::Gui_Handles,s::DArray{T,1,Array{T,1}},backup) where T
    if (getproperty(han.sc.thres_widgets.all,:active,Bool))|(getproperty(han.sc.gain_widgets.all,:active,Bool))
        @sync begin
            for p in procs(s)
                @async remotecall_wait((ss)->set_multiple_thres(localpart(ss),han,localindexes(ss)),p,s)
            end
        end
        for i=1:size(han.scale,1)
            f=open(string(backup,"thres/",i,".bin"),"w")
            write(f,-1*han.sc.thres/han.scale[i,1]+h.offset[i])
            close(f)
        end
    else
        (nn,mycore)=get_thres_id(s,han.sc.spike)
        remotecall_wait(((x,h,num)->remote_set_thres(localpart(x)[num],h)),mycore,s,han,nn)
        f=open(string(backup,"thres/",han.sc.spike,".bin"),"w")
        write(f,-1*han.sc.thres/han.sc.s+han.sc.o)
        close(f)
    end
end

function remote_set_thres(x,h)

    x.thres = -1 * h.sc.thres/h.sc.s + h.sc.o

    nothing
end

function get_thres_id(s::DArray{T,1,Array{T,1}},ss::Int64) where T

    mycore=1
    mynum=ss

    for i=2:(length(procs(s))+1)
        if ss<s.cuts[1][i]
            mycore=i
            mynum=ss-s.cuts[1][i-1]+1
            break
        end
    end
    (mynum,mycore)
end

function set_multiple_thres(s::Array,han::Gui_Handles,inds)
    @inbounds for i=1:length(s)
        s[i].thres=-1*han.sc.thres/han.scale[inds[1][i],1]+han.offset[inds[1][i]]
    end
end

#=
Get threshold from Sorting data structure and set threshold in GUI handles equal to it.
=#

function get_thres(han::Gui_Handles,s::DArray{T,1,Array{T,1}}) where T<:Sorting
    (nn,mycore)=get_thres_id(s,han.sc.spike)

    mythres=remotecall_fetch(((x,h,num)->(localpart(x)[num].thres-h.sc.o)*h.sc.s*-1),mycore,s,han,nn)

    setproperty!(han.sc.adj_thres,:value,round(Int64,mythres)) #show threshold

    nothing
end

function get_thres(han::Gui_Handles,s::Array{T,1}) where T<:Sorting

    mythres=(s[han.sc.spike].thres-han.sc.o)*han.sc.s*-1
    setproperty!(han.sc.adj_thres,:value,round(Int64,mythres)) #show threshold

    nothing
end

#=
Threshold Callbacks
=#

function sb2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.sc.gain_widgets.all,:active,Bool)

    gainval=getproperty(han.sc.gain_widgets.gainbox,:value,Int)
    mythres=getproperty(han.sc.adj_thres,:value,Int)

    if mygain==true
        han.scale[:,1] .= -1 .* gainval/1000
        han.scale[:,2] .= -.2 * gainval/1000

        for i=1:size(han.scale,1)
            f=open(string(rhd.save.backup,"gain/",i,".bin"),"w")
            write(f,han.scale[i,1])
            close(f)
        end
    else
        han.scale[han.sc.spike,1] = -1 * gainval/1000
        han.scale[han.sc.spike,2] = -.2 * gainval/1000

        f=open(string(rhd.save.backup,"gain/",han.sc.spike,".bin"),"w")
        write(f,han.scale[han.sc.spike,1])
        close(f)
    end

    han.sc.s = han.scale[han.sc.spike,1]

    han.sc.thres_changed=true

    nothing
end
