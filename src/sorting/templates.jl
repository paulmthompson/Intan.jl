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
            setproperty!(han.adj_sort, :value, 50)
            draw_templates(rhd,han)
        else #replace old cluster
            (mymean,mystd)=make_cluster(han.spike_buf,x1,y1,x2,y2,han.buf_count)
            change_cluster(rhd.s[han.spike].c,mymean,mystd,clus)
            setproperty!(han.adj_sort, :value, 50)
            draw_templates(rhd,han)
        end

        if (clus>0)&((han.buf_count>0)&(han.pause))
            template_cluster(han,clus,mymean,mystd[:,2],mystd[:,1],1.0)
            plot_new_color(han.ctx2,han,clus)
        end
    elseif event.button==3

    end
    
    nothing
end

#Delete clusters
function b1_cb_template(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data
    clus=han.clus

    if (clus<1) #do nothing if zeroth cluster selected      
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

    #setproperty!(han.adj_sort, :value, 50)

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
        han.hold=true
        han.pause=false
        change_button_label(mybutton,"Stop Collection")
    else
        
        Gtk.GAccessor.active(han.pause_button,true)
        change_button_label(mybutton,"Collect Templates")
    end
    
    nothing
end

function b4_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    ctx = han.ctx2s

    clus=han.clus

    if clus>0
        s=han.scale[han.spike,1]
        o=han.scale[han.spike]

        Cairo.translate(ctx,0.0,han.h2/2)
        scale(ctx,han.w2/han.wave_points,s)
        
        move_to(ctx,1.0,rhd.s[han.spike].c.templates[1,clus]+(rhd.s[han.spike].c.sig_max[1,clus]*rhd.s[han.spike].c.tol[clus])-o)

        for i=2:size(rhd.s[han.spike].c.templates,1)
            y=rhd.s[han.spike].c.templates[i,clus]+(rhd.s[han.spike].c.sig_max[i,clus]*rhd.s[han.spike].c.tol[clus])-o
            line_to(ctx,i,y)
        end

        y=rhd.s[han.spike].c.templates[end,clus]-(rhd.s[han.spike].c.sig_min[end,clus]*rhd.s[han.spike].c.tol[clus])-o
        
        line_to(ctx,size(rhd.s[han.spike].c.templates,1),y)

        for i=(size(rhd.s[han.spike].c.templates,1)-1):-1:1
            y=rhd.s[han.spike].c.templates[i,clus]-(rhd.s[han.spike].c.sig_min[i,clus]*rhd.s[han.spike].c.tol[clus])-o
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

function check_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    mycheck=convert(CheckButton,widget)

    if getproperty(mycheck,:active,Bool)
        han.sort_cb=true
    else
        han.sort_cb=false
    end

    if han.sort_cb
        draw_templates(rhd.s[han.spike].c,han)
    end
    
    nothing
end

function draw_templates(c::ClusterTemplate,han::Gui_Handles)

    ctx = han.ctx2s
    mywidth=width(ctx)
    myheight=height(ctx)

    s=han.scale[han.spike,1]
    o=han.scale[han.spike]
    
    Cairo.translate(ctx,0.0,myheight/2)
    scale(ctx,mywidth/han.wave_points,s)
    
    for clus=1:han.total_clus[han.spike]
        
        move_to(ctx,1.0,(c.templates[1,clus])-o)
        
        for i=2:size(c.sig_max,1)
            y=c.templates[i,clus]-o
            line_to(ctx,i,y)
        end
        
        select_color(ctx,clus+1)
        set_line_width(ctx,3.0)
        stroke(ctx)
    end
    identity_matrix(ctx)
    nothing
end

function template_slider(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han,rhd = user_data

    myval=getproperty(han.adj_sort, :value, Int64) # primary display

    clus=han.clus
    
    if clus>0

        rhd.s[han.spike].c.tol[clus] = myval/50.0

        if ((han.buf_count>0)&(han.pause))
            template_cluster(han,clus,rhd.s[han.spike].c.templates[:,clus],rhd.s[han.spike].c.sig_min[:,clus],rhd.s[han.spike].c.sig_max[:,clus],rhd.s[han.spike].c.tol[clus])
            plot_new_color(han.ctx2,han,clus)
        end
    end
end

function add_new_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,2})
    
    c.num += 1

    for i=1:length(mymean)
        c.templates[i,c.num] = mymean[i]
        c.sig_max[i,c.num]= mystd[i,1]
        c.sig_min[i,c.num]= mystd[i,2]
    end

    nothing
end

function change_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,2},n::Int64)

    for i=1:length(mymean)
        c.templates[i,n] = mymean[i]
        c.sig_max[i,n] = mystd[i,1]
        c.sig_min[i,n] = mystd[i,2]
    end

    nothing
end

function delete_cluster(c::ClusterTemplate,n::Int64)

    for i=1:size(c.templates,1)
        c.templates[i,n] = 0.0
        c.sig_max[i,n] = 0.0
        c.sig_min[i,n] = 0.0
    end

    c.tol[n]=0.0
    
    if n == c.num
        c.num -= 1
    else
        for i=n:(c.num-1)
            for j=1:size(c.templates,1) 
                c.templates[j,i]=c.templates[j,i+1]
                c.sig_max[j,i]=c.sig_max[j,i+1]
                c.sig_min[j,i]=c.sig_min[j,i+1]
            end
            c.tol[i]=c.tol[i+1]
        end
        c.num -= 1
    end
    
    nothing
end

function make_cluster(input,x1,y1,x2,y2,nn)
    
    hits=0
    mymean=zeros(Float64,size(input,1)-1)
    mysum=zeros(Int64,size(input,1)-1)
    mystd=zeros(Float64,size(input,1)-1)
    mybounds=zeros(Float64,size(input,1)-1,2)

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
                    if hits==1
                        mybounds[ii,1]=input[ii,i]
                        mybounds[ii,2]=input[ii,i]
                    else
                        if input[ii,i]>mybounds[ii,1]
                            mybounds[ii,1]=input[ii,i]
                        end
                        if input[ii,i]<mybounds[ii,2]
                            mybounds[ii,2]=input[ii,i]
                        end
                    end
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
        mybounds[i,2] = abs(mymean[i]-mybounds[i,2])
        mybounds[i,1] = abs(mybounds[i,1] - mymean[i])
    end
    
    (mymean,mybounds)
end

function template_cluster(han::Gui_Handles,clus::Int64,mymean::Array{Float64,1},mymin::Array{Float64,1},mymax::Array{Float64,1},tol::Float64)

    @inbounds for i=1:han.buf_ind

        mymisses=0
        for j=1:length(mymean)
            if (han.spike_buf[j,i]<(mymean[j]-(mymin[j]*tol)))|(han.spike_buf[j,i]>(mymean[j]+(mymax[j]*tol)))
                mymisses+=1
                if mymisses>5
                    break
                end
            end
        end
        if mymisses<5 #If passes template matching, set as unit
            han.buf_clus[i]=clus
        elseif han.buf_clus[i]==clus #If did not pass, but was previously, set to noise cluster
            #han.buf_clus[i]=0
            han.buf_clus[i]=-1
        end
    end

    nothing
end

function draw_templates(rhd::RHD2000,han::Gui_Handles)

    ctx=getgc(han.c3)

    myheight=height(ctx)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)

    for clus = 1:han.total_clus[han.spike]

        s=han.scale[han.spike,1]*.25
        o=han.scale[han.spike]

        Cairo.translate(ctx,0.0,50.0)
        scale(ctx,mywidth/(han.wave_points*total_clus),s)

        startx=(clus-1)*(han.wave_points)+1
        move_to(ctx,1.0+startx,rhd.s[han.spike].c.templates[1,clus]-o)

        for i=2:size(rhd.s[han.spike].c.sig_max,1)
            y=rhd.s[han.spike].c.templates[i,clus]-o
            line_to(ctx,i+startx,y)
        end
        
        select_color(ctx,clus+1)
        set_line_width(ctx,1.0)
        stroke(ctx)

        identity_matrix(ctx)
    end
    
    nothing
end
