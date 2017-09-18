#=
Template Matching Spike Sorting
=#

function slider_release_template(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data

    han.sort_widgets.slider_active = false
    
    nothing
end

function canvas_release_template(widget::Ptr,param_tuple,user_data::Tuple{SpikeSorting.Buffer,SpikeSorting.Single_Channel})

    buf,sc = user_data
    event = unsafe_load(param_tuple)

    clus=buf.selected_clus

    (x1,x2,y1,y2)=SpikeSorting.coordinate_transform(sc,event)
    
    if event.button==1

        if sc.pause_state == 1
            #Waveforms selected with a left click rubberband in the paused display will be used to form a cluster template for the currently selected cluster.
        
            if (clus==0) #do nothing if zeroth cluster    
            else

                buf.selected=trues(buf.ind)
                SpikeSorting.find_intersected_waveforms(buf.spikes,buf.selected,buf.ind,x1,y1,x2,y2)
            
                buf.c_changed=true
            end

            if (clus>0)&((buf.count>0)&(sc.pause))
                buf.replot=true
            end
        elseif sc.pause_state == 2
            if sc.pause

            end
        end
    elseif event.button==3

        if sc.pause_state == 1
            #Waveforms selected with right click in the paused display will be removed from display. If a cluster is selected, these waveforms will also be removed from that selected cluster
        
            if sc.pause
                SpikeSorting.find_intersected_waveforms(buf.spikes,buf.mask,buf.count,x1,y1,x2,y2)

                if clus>0
                    buf.selected=!(buf.clus.==clus)
                    buf.c_changed=true
                end
                buf.replot=true     
            end
        elseif sc.pause_state == 2
            if sc.pause
                
            end
        end   
    end
    
    nothing
end

#Delete clusters
function b1_cb_template(widgetptr::Ptr,user_data::Tuple{Gui_Handles})
    
    han, = user_data
    clus=han.buf.selected_clus

    if (clus<1) #do nothing if zeroth cluster selected      
    else
        delete_cluster(han.temp,clus)
        deleteat!(han.sort_list,han.total_clus[han.spike]+1)
        han.total_clus[han.spike] -= 1
        han.buf.selected_clus = 0
        selmodel=Gtk.GAccessor.selection(han.sort_tv)
        select!(selmodel, Gtk.iter_from_index(han.sort_list,1))
        han.buf.c_changed=true
    end
    nothing
end

#Add Unit
function b2_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles})
    
    han, = user_data
    
    #Add total number of units and go to that unit
    han.total_clus[han.spike] += 1
    han.temp.num += 1
    
    han.buf.selected_clus = han.total_clus[han.spike]
    push!(han.sort_list,(han.total_clus[han.spike],))

    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    select!(selmodel, Gtk.iter_from_index(han.sort_list, han.total_clus[han.spike]+1))
    
    nothing
end

function b3_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data

    mybutton = convert(Button, widget)

    if han.sc.pause
        Gtk.GAccessor.active(han.sc.pause_button,false)
    end
    
    if !han.sc.hold
        SpikeSorting.clear_c2(han.sc.c2,han.spike)
        han.sc.ctx2=getgc(han.sc.c2)
        han.sc.ctx2s=copy(han.sc.ctx2)
        han.buf.ind=1
        han.buf.count=1
        han.sc.hold=true
        han.sc.pause=false
        change_button_label(mybutton,"Stop Collection")
    else
        
        Gtk.GAccessor.active(han.sc.pause_button,true)
        change_button_label(mybutton,"Collect Templates")

        if han.buf.count==size(han.buf.spikes,2)
            han.buf.ind=han.buf.count
        end

        if visible(han.sortview_widgets.win)
            SpikeSorting.recalc_features(han.sortview_widgets)
            SpikeSorting.replot_sort(han.sortview_widgets)
        end
    end
    
    nothing
end

function b4_cb_template(widgetptr::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    widget = convert(ToggleButton, widgetptr)
    
    #Untoggle 
    if !getproperty(widget,:active,Bool)
        han.buf.replot=true
    else
        #Toggling, so draw template
        if han.sc.pause
            draw_template_bounds(han)
        end
    end

    nothing
end

function draw_template_bounds(han::Gui_Handles)

    ctx = han.sc.ctx2
    clus=han.buf.selected_clus
    
     if clus>0
            s=han.sc.s
            o=han.sc.o
            
            Cairo.translate(ctx,0.0,han.sc.h2/2)
            scale(ctx,han.sc.w2/han.sc.wave_points,s)
            
            move_to(ctx,1.0,han.temp.templates[1,clus]+(han.temp.sig_max[1,clus]*han.temp.tol[clus])-o)
            
            for i=2:size(han.temp.templates,1)
                y=han.temp.templates[i,clus]+(han.temp.sig_max[i,clus]*han.temp.tol[clus])-o
                line_to(ctx,i,y)
            end
            
            y=han.temp.templates[end,clus]-(han.temp.sig_min[end,clus]*han.temp.tol[clus])-o
            
            line_to(ctx,size(han.temp.templates,1),y)
            
            for i=(size(han.temp.templates,1)-1):-1:1
                y=han.temp.templates[i,clus]-(han.temp.sig_min[i,clus]*han.temp.tol[clus])-o
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
end

function check_cb_template(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    
    mycheck=convert(CheckButton,widget)

    if getproperty(mycheck,:active,Bool)
        han.sort_cb=true
    else
        han.sort_cb=false
    end

    if han.sort_cb
        draw_templates(han)
    end
    
    nothing
end

function draw_templates(han::Gui_Handles)

    ctx = han.sc.ctx2s
    mywidth=width(ctx)
    myheight=height(ctx)

    s=han.sc.s
    o=han.sc.o
    
    Cairo.translate(ctx,0.0,myheight/2)
    scale(ctx,mywidth/han.wave_points,s)
    
    for clus=1:han.total_clus[han.spike]
        
        move_to(ctx,1.0,(han.temp.templates[1,clus])-o)
        
        for i=2:size(han.temp.sig_max,1)
            y=han.temp.templates[i,clus]-o
            line_to(ctx,i,y)
        end
        
        select_color(ctx,clus+1)
        set_line_width(ctx,3.0)
        stroke(ctx)
    end
    identity_matrix(ctx)
    nothing
end

function template_slider(widget::Ptr,user_data::Tuple{Gui_Handles})
    
    han, = user_data

    if !han.sort_widgets.slider_active
        han.sort_widgets.slider_active = true      
    end

    myval=getproperty(han.adj_sort, :value, Float64) # primary display

    clus=han.buf.selected_clus
    
    if clus>0

        han.temp.tol[clus] = myval

        if ((han.buf.count>0)&(han.sc.pause))
            template_cluster(han,clus,han.temp.templates[:,clus],han.temp.sig_min[:,clus],han.temp.sig_max[:,clus],han.temp.tol[clus])
            replot_all_spikes(han)

            #incremental plot 
        end
    end
    han.c_changed=true
    nothing
end

function change_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,2},n)

    for i=1:length(mymean)
        c.templates[i,n] = mymean[i]
        c.sig_max[i,n] = mystd[i,1]
        c.sig_min[i,n] = mystd[i,2]
    end

    nothing
end

function delete_cluster(c::ClusterTemplate,n)

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

#=
Calculates the mean and bounds for a collection of spikes that
1) are not hidden by the mask vector
2) meet some condition

examples of this condition could be whether the spikes are contained within a rubberband, or if they are part of a certain cluster already
=#
function make_cluster{T}(input::Array{T,2},mask,count,condition)
    
    hits=0
    mymean=zeros(Float64,size(input,1)-1)
    mysum=zeros(Int64,size(input,1)-1)
    mybounds=zeros(Float64,size(input,1)-1,2)

    for i=1:count
        if (condition[i])&&(mask[i])
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

function template_cluster(han::Gui_Handles,clus,mymean::Array{Float64,1},mymin::Array{Float64,1},mymax::Array{Float64,1},tol::Float64)

    @inbounds for i=1:han.buf.ind

        mymisses=0
        for j=1:length(mymean)
            if (han.buf.spikes[j,i]<(mymean[j]-(mymin[j]*tol)))|(han.buf.spikes[j,i]>(mymean[j]+(mymax[j]*tol)))
                mymisses+=1
                if mymisses>1
                    break
                end
            end
        end
        if mymisses<1 #If passes template matching, set as unit
            han.buf.clus[i]=clus
        elseif han.buf.clus[i]==clus #If did not pass, but was previously, set to noise cluster
            han.buf.clus[i]=0
        end
    end

    nothing
end

function draw_templates_c3(han::Gui_Handles)

    ctx=getgc(han.sc.c3)

    myheight=height(ctx)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)

    for clus = 1:han.total_clus[han.spike]

        s=han.sc.s * .25
        o=han.sc.o

        Cairo.translate(ctx,0.0,50.0)
        scale(ctx,mywidth/(han.wave_points*total_clus),s)

        startx=(clus-1)*(han.wave_points)+1
        move_to(ctx,1.0+startx,han.temp.templates[1,clus]-o)

        for i=2:size(han.temp.sig_max,1)
            y=han.temp.templates[i,clus]-o
            line_to(ctx,i+startx,y)
        end
        
        select_color(ctx,clus+1)
        set_line_width(ctx,1.0)
        stroke(ctx)

        identity_matrix(ctx)
    end
    
    nothing
end
