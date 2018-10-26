#=
Template Matching Spike Sorting
=#

function slider_release_template(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data

    han.sort_widgets.slider_active = false

    nothing
end

function template_slider(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data

    if !han.sort_widgets.slider_active
        han.sort_widgets.slider_active = true
    end

    myval=getproperty(han.sc.adj_sort, :value, Float64) # primary display

    clus=han.buf.selected_clus

    if clus>0

        han.sc.temp.tol[clus] = myval

        if ((han.buf.count>0)&(han.sc.pause))
            SpikeSorting.template_cluster(han.sc,clus,han.sc.temp.templates[:,clus],han.sc.temp.sig_min[:,clus],han.sc.temp.sig_max[:,clus],han.sc.temp.tol[clus])
            SpikeSorting.replot_all_spikes(han.sc)

            #incremental plot
        end
    end
    han.c_changed=true
    nothing
end

function draw_templates_c3(sc::SpikeSorting.Single_Channel)

    ctx=Gtk.getgc(sc.c3)

    myheight=height(ctx)
    mywidth=width(ctx)

    total_clus = max(sc.total_clus+1,5)

    for clus = 1:sc.total_clus

        s=sc.s * .25
        o=sc.o

        Cairo.translate(ctx,0.0,50.0)
        Gtk.scale(ctx,mywidth/(sc.wave_points*total_clus),s)

        startx=(clus-1)*(sc.wave_points)+1
        move_to(ctx,1.0+startx,sc.temp.templates[1,clus]-o)

        for i=2:size(sc.temp.sig_max,1)
            y=sc.temp.templates[i,clus]-o
            line_to(ctx,i+startx,y)
        end

        select_color(ctx,clus+1)
        set_line_width(ctx,1.0)
        stroke(ctx)

        identity_matrix(ctx)
    end

    nothing
end
