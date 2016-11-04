#=
Template Matching Spike Sorting
=#

function canvas_release_template(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)

    clus=han.var1[han.spike,2]
    
    if event.button==1
        
        (x1,x2,y1,y2)=coordinate_transform(han,event)

        if (han.var1[han.spike,2]==0) #do nothing if zeroth cluster    
        elseif (rhd.s[han.spike].c.num < han.var1[han.spike,2]) #new cluster

            (mymean,mystd)=make_cluster(han.spike_buf,x1,y1,x2,y2,han.buf_count)
            han.var1[han.spike,1] += 1
            add_new_cluster(rhd.s[han.spike].c,mymean,mystd)
            mytol=rhd.s[han.spike].c.sigmas[1,clus]
            setproperty!(han.adj_sort, :value, div(mytol,10))
             push!(han.sort_list,(clus,))
        else #replace old cluster
            (mymean,mystd)=make_cluster(han.spike_buf,x1,y1,x2,y2,han.buf_count)
            change_cluster(rhd.s[han.spike].c,mymean,mystd,han.var1[han.spike,2])
            mytol=rhd.s[han.spike].c.sigmas[1,clus]
            setproperty!(han.adj_sort, :value, div(mytol,10))
        end

        if (han.var1[han.spike,2]>0)&((han.buf_count>0)&(han.pause))
            template_cluster(han,han.var1[han.spike,2],mymean,mystd)
            plot_new_color(getgc(han.c2),han,han.var1[han.spike,2])
        end
    end
    
    nothing
end

#Delete clusters
function b1_cb_template(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data

    if (han.var1[han.spike,2]==0)||(han.var1[han.spike,2]>han.var1[han.spike,1]) #do nothing if zeroth cluster selected      
    else
        delete_cluster(rhd.s[han.spike].c,han.var1[han.spike,2])
        deleteat!(han.sort_list,han.var1[han.spike,2])
        han.var1[han.spike,1]-= 1
        han.var1[han.spike,2] = 0
        setproperty!(han.tb1,:label,string("Cluster: ",han.var1[han.spike,2]))
        
    end
    nothing
end

#Select Cluster
function b2_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data
    
    #go to next cluster
    clus=han.var1[han.spike,2]+1

    #Cycle back to beginning
    if clus==han.var1[han.spike,1]+2
        han.var1[han.spike,2]=0
        
    elseif clus==han.var1[han.spike,1]+1
        #create new cluster
        han.var1[han.spike,2]=clus
        setproperty!(han.adj_sort, :value, 50)
       
    else
        han.var1[han.spike,2]=clus
        if clus>0
            mytol=rhd.s[han.spike].c.sigmas[1,clus]
            setproperty!(han.adj_sort, :value, div(mytol,10))
        end
    end

    setproperty!(han.tb1,:label,string("Cluster: ",han.var1[han.spike,2]))
        
    nothing
end

function b3_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    ctx = getgc(han.c2)

    if han.var1[han.spike,2]>0
        s=han.scale[han.spike,1]
        o=han.scale[han.spike]

        Cairo.translate(ctx,0.0,300.0)
        scale(ctx,500/han.wave_points,s)
        
        move_to(ctx,1.0,(rhd.s[han.spike].c.templates[1,han.var1[han.spike,2]]+rhd.s[han.spike].c.sigmas[1,han.var1[han.spike,2]]-o))

        for i=2:size(rhd.s[han.spike].c.sigmas,1)
            y=rhd.s[han.spike].c.templates[i,han.var1[han.spike,2]]+rhd.s[han.spike].c.sigmas[i,han.var1[han.spike,2]]-o
            line_to(ctx,i,y)
        end

        y=rhd.s[han.spike].c.templates[end,han.var1[han.spike,2]]-rhd.s[han.spike].c.sigmas[end,han.var1[han.spike,2]]-o
        
        line_to(ctx,size(rhd.s[han.spike].c.sigmas,1),y)

        for i=(size(rhd.s[han.spike].c.sigmas,1)-1):-1:1
            y=rhd.s[han.spike].c.templates[i,han.var1[han.spike,2]]-rhd.s[han.spike].c.sigmas[i,han.var1[han.spike,2]]-o
            line_to(ctx,i,y)
        end

        close_path(ctx)
        
        select_color(ctx,han.var1[han.spike,2]+1)
        set_line_width(ctx,3.0)
        stroke_preserve(ctx)

        select_color(ctx,han.var1[han.spike,2]+1,.5)
        fill(ctx)
    end

    identity_matrix(ctx)

    nothing
end

function template_slider(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han,rhd = user_data

    myval=getproperty(han.adj_sort, :value, Int64) # primary display

    if han.var1[han.spike,2]<=han.var1[han.spike,1]
        if han.var1[han.spike,2]>0
            for i=1:size(rhd.s[han.spike].c.sigmas,1)
                rhd.s[han.spike].c.sigmas[i,han.var1[han.spike,2]]=10.0*myval
            end
        end

        if (han.var1[han.spike,2]>0)&((han.buf_count>0)&(han.pause))
            template_cluster(han,han.var1[han.spike,2],rhd.s[han.spike].c.templates[:,han.var1[han.spike,2]],rhd.s[han.spike].c.sigmas[:,han.var1[han.spike,2]])
            plot_new_color(getgc(han.c2),han,han.var1[han.spike,2])
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

function template_select_cb(widgetptr::Ptr,param_tuple1,param_tuple2,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data  
    get_cluster_id(han)
    
    nothing
end

function get_cluster_id(han::Gui_Handles)
    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    iter=Gtk.selected(selmodel)

    myind=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.sort_list), iter))
end
