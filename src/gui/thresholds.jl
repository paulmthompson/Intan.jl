
#=
Set Threshold for sorting equal to GUI threshold
=#
function thres_changed(han::Gui_Handles,s,fpga,backup)

    mythres=getproperty(han.adj_thres,:value,Int)
    han.sc.thres=mythres

    update_thres(han,s,backup)

    send_thres_to_ic(han,fpga)

    han.thres_changed=false
    
    nothing
end

#=
Functions used to update Sorting data structure with threshold from slider
=#
function update_thres(han::Gui_Handles,s::Array,backup)
    if (getproperty(han.thres_widgets.all,:active,Bool))|(getproperty(han.gain_widgets.all,:active,Bool))
        @inbounds for i=1:length(s)
            s[i].thres=-1*han.sc.thres/han.scale[i,1]+han.offset[i]
            f=open(string(backup,"thres/",i,".bin"),"w")
            write(f,s[i].thres)
            close(f)
        end    
    else
        @inbounds s[han.spike].thres=-1*han.sc.thres/han.sc.s+han.sc.o
        f=open(string(backup,"thres/",han.spike,".bin"),"w")
        write(f,s[han.spike].thres)
        close(f)
    end
end

function update_thres{T}(han::Gui_Handles,s::DArray{T,1,Array{T,1}},backup)
    if (getproperty(han.thres_widgets.all,:active,Bool))|(getproperty(han.gain_widgets.all,:active,Bool))
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
        (nn,mycore)=get_thres_id(s,han.spike)
        remotecall_wait(((x,h,num)->remote_set_thres(localpart(x)[num],h)),mycore,s,han,nn)
        f=open(string(backup,"thres/",han.spike,".bin"),"w")
        write(f,-1*han.sc.thres/han.sc.s+han.sc.o)
        close(f)
    end
end

function remote_set_thres(x,h)

    x.thres = -1 * h.sc.thres/h.sc.s + h.sc.o
    
    nothing
end

function get_thres_id{T}(s::DArray{T,1,Array{T,1}},ss::Int64)

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

function get_thres{T<:Sorting}(han::Gui_Handles,s::DArray{T,1,Array{T,1}})
    (nn,mycore)=get_thres_id(s,han.spike)
    
    mythres=remotecall_fetch(((x,h,num)->(localpart(x)[num].thres-h.sc.o)*h.sc.s*-1),mycore,s,han,nn)

    setproperty!(han.adj_thres,:value,round(Int64,mythres)) #show threshold

    nothing
end

function get_thres{T<:Sorting}(han::Gui_Handles,s::Array{T,1})

    mythres=(s[han.spike].thres-han.sc.o)*han.sc.s*-1
    setproperty!(han.adj_thres,:value,round(Int64,mythres)) #show threshold

    nothing
end

#=
Threshold Callbacks
=#

function thres_show_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    mywidget = convert(CheckButton, widget)
    han.sc.show_thres=getproperty(mywidget,:active,Bool)
    han.sc.old_thres=getproperty(han.adj_thres,:value,Int)
    han.sc.thres=getproperty(han.adj_thres,:value,Int)

    nothing
end

function thres_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han,  = user_data

    mythres=getproperty(han.adj_thres,:value,Int)
    setproperty!(han.thres_widgets.sb,:label,string(mythres))
    han.thres_changed=true

    nothing
end

function sb2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain_widgets.all,:active,Bool)

    gainval=getproperty(han.gain_widgets.gainbox,:value,Int)
    mythres=getproperty(han.adj_thres,:value,Int)

    if mygain==true
        han.scale[:,1]=-1.*gainval/1000
        han.scale[:,2]=-.2*gainval/1000

        for i=1:size(han.scale,1)
            f=open(string(rhd.save.backup,"gain/",i,".bin"),"w")
            write(f,han.scale[i,1])
            close(f)
        end
    else
        han.scale[han.spike,1]=-1*gainval/1000
        han.scale[han.spike,2]=-.2*gainval/1000
        
        f=open(string(rhd.save.backup,"gain/",han.spike,".bin"),"w")
        write(f,han.scale[han.spike,1])
        close(f)
    end

    han.sc.s = han.scale[han.spike,1]

    han.thres_changed=true

    nothing
end

function gain_check_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data

    mygain=getproperty(han.gain_widgets.multiply,:active,Bool)

    if mygain
        Gtk.GAccessor.increments(han.gain_widgets.gainbox,10,10)
    else
        Gtk.GAccessor.increments(han.gain_widgets.gainbox,1,1)
    end

    nothing
end



