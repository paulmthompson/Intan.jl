#=
Template Matching Spike Sorting
=#

function canvas_release_template(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)

    clus=han.clus
    
    if event.button==1 #Left click
        
        (x1,x2,y1,y2)=coordinate_transform(han,event)

        if (clus==0) #do nothing if zeroth cluster    
        elseif (rhd.s[han.spike].c.num < clus) #new cluster

            (mymean,mystd)=make_cluster(han.spike_buf,x1,y1,x2,y2,han.buf_count)
            add_new_cluster(rhd.s[han.spike].c,mymean,mystd)
            mytol=rhd.s[han.spike].c.sigmas[1,clus]
            setproperty!(han.adj_sort, :value, div(mytol,10))
        else #replace old cluster
            (mymean,mystd)=make_cluster(han.spike_buf,x1,y1,x2,y2,han.buf_count)
            change_cluster(rhd.s[han.spike].c,mymean,mystd,clus)
            mytol=rhd.s[han.spike].c.sigmas[1,clus]
            setproperty!(han.adj_sort, :value, div(mytol,10))
        end

        if (clus>0)&((han.buf_count>0)&(han.pause))
            template_cluster(han,clus,mymean,mystd)
            plot_new_color(getgc(han.c2),han,clus)
        end
    end
    
    nothing
end

#Delete clusters
function b1_cb_template(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data
    clus=han.clus

    if (clus==0) #do nothing if zeroth cluster selected      
    else
        delete_cluster(rhd.s[han.spike].c,clus)
        deleteat!(han.sort_list,han.total_clus[han.spike]+1)
        han.total_clus[han.spike] -= 1
        han.clus = 0
        selmodel=Gtk.GAccessor.selection(han.sort_tv)
        select!(selmodel, Gtk.iter_from_index(han.sort_list,1))
    end
    nothing
end

#Add Unit
function b2_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data
    
    #Add total number of units and go to that unit
    han.total_clus[han.spike] += 1
    han.clus = han.total_clus[han.spike]
    push!(han.sort_list,(han.total_clus[han.spike],))

    setproperty!(han.adj_sort, :value, 0)

    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    select!(selmodel, Gtk.iter_from_index(han.sort_list, han.total_clus[han.spike]+1))
    
    nothing
end

function b3_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mybutton = convert(Button, widget)

    if han.pause
        Gtk.GAccessor.active(han.pause_button,false)
    end
    
    if !han.hold
        clear_c2(han.c2,han.spike)
    
        if getproperty(han.buf_button,:active,Bool)
            han.buf_ind=1
            han.buf_count=1
        end
        if han.show_thres==true
            plot_thres(han,rhd,rhd.s[1].d)
        end
        han.hold=true
        han.pause=false
        setproperty!(mybutton,:label,"Stop Collection")
    else
        
        Gtk.GAccessor.active(han.pause_button,true)
        setproperty!(mybutton,:label,"Collect Templates")
    end
    
    nothing
end

function b4_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    ctx = getgc(han.c2)

    clus=han.clus

    if clus>0
        s=han.scale[han.spike,1]
        o=han.scale[han.spike]

        Cairo.translate(ctx,0.0,300.0)
        scale(ctx,500/han.wave_points,s)
        
        move_to(ctx,1.0,(rhd.s[han.spike].c.templates[1,clus]+rhd.s[han.spike].c.sigmas[1,clus]-o))

        for i=2:size(rhd.s[han.spike].c.sigmas,1)
            y=rhd.s[han.spike].c.templates[i,clus]+rhd.s[han.spike].c.sigmas[i,clus]-o
            line_to(ctx,i,y)
        end

        y=rhd.s[han.spike].c.templates[end,clus]-rhd.s[han.spike].c.sigmas[end,clus]-o
        
        line_to(ctx,size(rhd.s[han.spike].c.sigmas,1),y)

        for i=(size(rhd.s[han.spike].c.sigmas,1)-1):-1:1
            y=rhd.s[han.spike].c.templates[i,clus]-rhd.s[han.spike].c.sigmas[i,clus]-o
            line_to(ctx,i,y)
        end

        close_path(ctx)
        
        select_color(ctx,clus+1)
        set_line_width(ctx,3.0)
        stroke_preserve(ctx)

        select_color(ctx,clus+1,.5)
        fill(ctx)
    end

    identity_matrix(ctx)

    nothing
end

function template_slider(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han,rhd = user_data

    myval=getproperty(han.adj_sort, :value, Int64) # primary display

    clus=han.clus
    
    if clus>0
        for i=1:size(rhd.s[han.spike].c.sigmas,1)
            rhd.s[han.spike].c.sigmas[i,clus]=10.0*myval
        end
        
        if ((han.buf_count>0)&(han.pause))
            template_cluster(han,clus,rhd.s[han.spike].c.templates[:,clus],rhd.s[han.spike].c.sigmas[:,clus])
            plot_new_color(getgc(han.c2),han,clus)
        end
    end
end

function add_new_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,1})
    
    c.num += 1

    for i=1:length(mymean)
        c.templates[i,c.num] = mymean[i]
        c.sigmas[i,c.num]= mystd[i]
    end

    nothing
end

function change_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,1},n::Int64)

    for i=1:length(mymean)
        c.templates[i,n] = mymean[i]
        c.sigmas[i,n] = mystd[i]
    end

    nothing
end

function delete_cluster(c::ClusterTemplate,n::Int64)

    for i=1:size(c.templates,1)
        c.templates[i,n] = 0.0
        c.sigmas[i,n] = 0.0
    end
    
    if n == c.num
        c.num -= 1
    else
        for i=n:(c.num-1)
            for j=1:size(c.templates,1) 
                c.templates[j,i]=c.templates[j,i+1]
                c.sigmas[j,i]=c.sigmas[j,i+1]
            end
        end
        c.num -= 1
    end
    
    nothing
end

function make_cluster(input,x1,y1,x2,y2,nn)
    
    hits=0
    mymean=zeros(Float64,size(input,1)-1)
    mysum=zeros(Int64,size(input,1)-1)
    mysquares=zeros(Int64,size(input,1)-1)
    mystd=zeros(Float64,size(input,1)-1)

    if x1<3
        x1=2
    end
    if x2>(size(input,1)-3)
        x2=size(input,1)-3
    end
    
    for i=1:nn
        for j=(x1-1):(x2+1)
            if SpikeSorting.intersect(x1,x2,j,j+1,y1,y2,input[j,i],input[j+1,i])
                hits+=1
                for ii=1:length(mymean)
                    mysum[ii] += input[ii,i]
                    mysquares[ii] += input[ii,i]*input[ii,i]
                end
                break
            end
        end
    end

    if hits==0
        hits=1
    end
    
    for i=1:length(mymean)
        mymean[i] = mysum[i]/hits
        mystd[i] = sqrt(abs(mysquares[i]- (mysum[i]*mysum[i])/hits)/hits)
    end

    mystd[:]=std(mymean)
    
    (mymean,mystd)
end

function template_cluster(han::Gui_Handles,clus::Int64,mymean::Array{Float64,1},mystd::Array{Float64,1})

    @inbounds for i=1:han.buf_ind

        mymisses=0
        for j=1:size(han.spike_buf,1)
            if (han.spike_buf[j,i]<(mymean[j]-mystd[j]))|(han.spike_buf[j,i]>(mymean[j]+mystd[j]))
                mymisses+=1
                if mymisses>5
                    break
                end
            end
        end
        if mymisses<5 #If passes template matching, set as unit
            han.buf_clus[i]=clus
        elseif han.buf_clus[i]==clus #If did not pass, but was previously, set to noise cluster
            han.buf_clus[i]=0
        end
    end

    nothing
end
