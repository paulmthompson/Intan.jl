#=
Window Discriminator Spike Sorting
=#

function canvas_release_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    event = unsafe_load(param_tuple)
    han, rhd = user_data
    if event.button==1
        
        (x1,x2,y1,y2)=coordinate_transform(han,event)

        #If this is distributed, it is going to be *really* slow
        #because it will be sending over the entire DArray from whatever processor
        #Change this so it is just communicating with the cluster part; JNeuron does something similar
        if (han.clus==0)||(han.var2[han.spike,2]==0) #do nothing if zeroth cluster or window      
        elseif (length(rhd.s[han.spike].c.win) < han.clus) #new cluster
            push!(rhd.s[han.spike].c.win,[SpikeSorting.mywin(x1,x2,y1,y2)])
            push!(rhd.s[han.spike].c.hits,0)
            han.total_clus[han.spike] += 1
            han.var2[han.spike,1]+=1
            han.spike_win=rhd.s[han.spike].c.win[end]
        elseif length(rhd.s[han.spike].c.win[han.clus]) < han.var2[han.spike,2] #new window
            push!(rhd.s[han.spike].c.win[han.clus],SpikeSorting.mywin(x1,x2,y1,y2))
            han.var2[han.spike,1]+=1
            han.spike_win=rhd.s[han.spike].c.win[han.clus]
        else #replace old window
            rhd.s[han.spike].c.win[han.clus][han.var2[han.spike,2]]=SpikeSorting.mywin(x1,x2,y1,y2)
            han.spike_win=rhd.s[han.spike].c.win[han.clus]
        end

        if ((han.clus>0)&(han.var2[han.spike,2]>0))&((han.buf_count>0)&(han.pause))

            window_cluster(han,han.clus)
            plot_new_color(getgc(han.c2),han,han.clus)
        end
    end
    
    nothing
end

#Delete clusters
function b1_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    if (han.clus==0)||(han.clus>han.total_clus[han.spike]) #do nothing if zeroth cluster selected      
    else
        deleteat!(rhd.s[han.spike].c.win,han.clus)
        pop!(rhd.s[han.spike].c.hits)
        han.total_clus[han.spike] -= 1
        han.clus = 0
        han.var2[han.spike,1] = 0
        han.var2[han.spike,2] = 0
        setproperty!(han.tb1,:label,string("Cluster: ",han.var1[han.spike,2]))
        setproperty!(han.tb2,:label,"Window: 0")
    end
    nothing
end

#Delete Window
function b2_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data 

    if (han.var2[han.spike,2]==0)||(han.var2[han.spike,2]>han.var2[han.spike,1]) #do nothing if zeroth window
    else
        deleteat!(rhd.s[han.spike].c.win[han.clus],han.var2[han.spike,2])
        han.var2[han.spike,1]-= 1
        han.var2[han.spike,2] = 0
        setproperty!(han.tb2,:label,"Window: 0")
    end
    
    nothing
end

#Display Windows
function b3_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data   
    ctx = getgc(han.c2)

    increment=div(500,han.wave_points)
        
    #loop over clusters
    for i=1:length(rhd.s[han.spike].c.win)
        #loop over windows
        for j=1:length(rhd.s[han.spike].c.win[i])

            x1=(rhd.s[han.spike].c.win[i][j].x1-1)*increment+1
            x2=(rhd.s[han.spike].c.win[i][j].x2-1)*increment+1
            y1=rhd.s[han.spike].c.win[i][j].y1
            y2=rhd.s[han.spike].c.win[i][j].y2
            move_to(ctx,x1,(y1-han.offset[han.spike])*han.scale[han.spike,1]+300)
            line_to(ctx,x2,(y2-han.offset[han.spike])*han.scale[han.spike,1]+300)
            set_line_width(ctx,5.0)
            select_color(ctx,i+1)
            stroke(ctx)
        end
    end
     
    reveal(han.c2)

    nothing
end

#Select Cluster
function b4_cb_win(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    #go to next cluster
    clus=han.clus+1

    if clus==han.total_clus[han.spike]+2
        han.clus=0
        han.var2[han.spike,1]=0
    elseif clus==han.total_clus[han.spike]+1
        #create new cluster
        han.clus=clus
        han.var2[han.spike,1]=0
    else
        han.clus=clus
        han.var2[han.spike,1]=length(rhd.s[han.spike].c.win)
    end
            
    #reset currently selected window to zero
    han.var2[han.spike,2]=0

    setproperty!(han.tb1,:label,string("Cluster: ",han.clus))
    setproperty!(han.tb2,:label,"Window: 0")
        
    nothing
end

#Select Window
function b5_cb_win(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    #go to next window
    win=han.var2[han.spike,2]+1

    if win==han.var2[han.spike,1]+2
        han.var2[han.spike,2]=0
    elseif win==han.var1[han.spike,1]+1
        #create new window
        han.var2[han.spike,2]=win
    else
        han.var2[han.spike,2]=win
    end
        
    setproperty!(han.tb2,:label,string("Window: ",han.var2[han.spike,2]))

    nothing
end

#Finds all spikes in buffer that are selected by windows
function window_cluster(han::Gui_Handles,clus::Int64)

    @inbounds for i=1:han.buf_ind

        hits=0
        for j=1:length(han.spike_win) #Loop over all windows
            a1=han.spike_win[j].x1
            a2=han.spike_win[j].x2
            b1=han.spike_win[j].y1
            b2=han.spike_win[j].y2
            for k=(han.spike_win[j].x1-1):(han.spike_win[j].x2+1)
                if SpikeSorting.intersect(a1,a2,k,k+1,b1,b2,han.spike_buf[k,i],han.spike_buf[k+1,i])
                    hits+=1
                    break
                end
            end
        end
        if hits==length(han.spike_win)
            han.buf_clus[i]=clus
        end
    end

    nothing
end
