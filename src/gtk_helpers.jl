
#import ..Gtk: suffix

#Gtk.@gtktype GtkCheckMenuItem
#Gtk.@gtktype_custom_symname(GtkCheckMenuItem, gtk_check_menu_item)
#Gtk.@Gtype GtkCheckMenuItem Gtk.libgtk gtk_check_menu_item

#const CheckMenuItemLeaf = GtkCheckMenuItem
#const CheckMenuItem = GtkCheckMenuItem
#Gtk.@g_type_delegate CheckMenuItem = GtkCheckMenuItem

#GtkCheckMenuItem() = GtkCheckMenuItem(ccall((:gtk_check_menu_item_new, Gtk.libgtk), Ptr{GObject}, ()))

#GtkCheckMenuItem(title::String) = GtkCheckMenuItem(ccall((:gtk_check_menu_item_new_with_label,Gtk.libgtk),Ptr{GObject},(Ptr{UInt8},),string(title)))

#Gtk.@gtktype GtkRadioMenuItem

#Gtk.@Gtype GtkRadioMenuItem Gtk.libgtk gtk_radio_menu_item

#const RadioMenuItemLeaf = GtkRadioMenuItem
#const RadioMenuItem = GtkRadioMenuItem
#Gtk.@g_type_delegate RadioMenuItem = GtkRadioMenuItem

#GtkRadioMenuItem(group::Ptr{Void} = C_NULL) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new, Gtk.libgtk), Ptr{GObject}, (Ptr{Void},),group))

#GtkRadioMenuItem(label::String) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new_with_mnemonic,Gtk.libgtk),Ptr{GObject},(Ptr{Void},Ptr{UInt8}),C_NULL,string(label)))

#GtkRadioMenuItem(group::GtkRadioMenuItem,title::String) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new_with_label_from_widget,Gtk.libgtk),Ptr{GObject},(Ptr{GObject},Ptr{UInt8}),group,string(title)))

#set_active!(group::GtkRadioMenuItem) = ccall((:gtk_check_menu_item_set_active,Gtk.libgtk),Void,(Ptr{GObject},Bool),group,true)

function add_button_label(button,mylabel)
    b_label=Label(mylabel)
    Gtk.GAccessor.markup(b_label, string("""<span size="x-small">""",mylabel,"</span>"))
    push!(button,b_label)
    show(b_label)
end

function line(ctx,x1,x2,y1,y2)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y2)
    nothing
end

function draw_box(x1,y1,x2,y2,mycolor,linewidth,ctx)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y1)
    line_to(ctx,x2,y2)
    line_to(ctx,x1,y2)
    line_to(ctx,x1,y1)
    set_source_rgb(ctx,mycolor[1],mycolor[2],mycolor[3])
    set_line_width(ctx,linewidth)
    stroke(ctx)
    nothing
end
