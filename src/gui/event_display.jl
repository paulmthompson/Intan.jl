
function _make_event_gui()

    popup_event = Menu()
    if VERSION > v"0.7-"
        event_handles=Array{MenuItemLeaf}(undef,0)
    else
        event_handles=Array{MenuItemLeaf}(0)
    end
    for i=1:8
        push!(event_handles,MenuItem(string("Analog ",i)))
        push!(popup_event,event_handles[i])
    end

    for i=1:16
        push!(event_handles,MenuItem(string("TTL ",i)))
        push!(popup_event,event_handles[8+i])
    end

    popup_event_none=MenuItem("None")
    push!(popup_event,popup_event_none)
    Gtk.showall(popup_event)

    (event_handles,popup_event,popup_event_none)
end

function add_event_callbacks(event_handles,popup_event_none,handles)

    for i=1:8
        signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    for i=9:24
        signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    signal_connect(popup_event_cb,popup_event_none,"activate",Void,(),false,(handles,-1))

    nothing
end

function popup_event_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    ctx=Gtk.getgc(han.c)
    myheight=height(ctx)

    chan_id=1
    if han.mim[2]<(myheight-250)
        chan_id=1
    elseif han.mim[2]<(myheight-200)
        chan_id=2
    elseif han.mim[2]<(myheight-150)
        chan_id=3
    elseif han.mim[2]<(myheight-100)
        chan_id=4
    elseif han.mim[2]<(myheight-50)
        chan_id=5
    else
        chan_id=6
    end

    han.events[chan_id]=event_id

    nothing
end


#Event plotting

function plot_events(fpga::Array{FPGA,1},han::Gui_Handles,myreads::Int64)

    @inbounds for i=1:6
	if han.events[i]>-1
	    if han.events[i]<8 #analog
		val=parse_analog(fpga[1].adc,han.events[i]+1)
		plot_analog(han,i,myreads,val)
	    else
		val=parse_ttl(fpga[1].ttlin,han.events[i]-7)
		plot_ttl(han,i,myreads,val)
	    end
	end
    end

    nothing
end

function plot_events(fpga::DArray{FPGA,1,Array{FPGA,1}},han::Gui_Handles,myreads::Int64)

    nothing
end

function parse_analog(adc::Array,chan::Int64)

    mysum=0
    for i=1:size(adc,1)
	mysum+=adc[i,chan]
    end

    round(Int64,mysum/size(adc,1)/0xffff*30)
end

function plot_analog(han::Gui_Handles,channel::Int64,myreads::Int64,val::Int64)

    ctx=Gtk.getgc(han.c)
    myheight=height(ctx)

    move_to(ctx,myreads-1,myheight-260 + (channel-1)*50-val)
    line_to(ctx,myreads,myheight-260 + (channel-1)*50-val)
    set_source_rgb(ctx,1.0,1.0,0.0)
    stroke(ctx)

    nothing
end

function parse_ttl(ttlin::Array,chan::Int64)

    y=0

    for i=1:length(ttlin)
        y=y|(ttlin[i]&(2^(chan-1)))
    end

    y>0
end

function plot_ttl(han::Gui_Handles,channel::Int64,myreads::Int64,val::Bool)

    ctx=Gtk.getgc(han.c)
    myheight=height(ctx)

    offset=0
    if val==true
	offset=30
    end

    move_to(ctx,myreads-1,myheight-260+(channel-1)*50-offset)
    line_to(ctx,myreads,myheight-260+(channel-1)*50-offset)
    set_source_rgb(ctx,1.0,1.0,0.0)
    stroke(ctx)

    nothing
end
