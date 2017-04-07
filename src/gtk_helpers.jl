
import ..Gtk: suffix

Gtk.@gtktype GtkCheckMenuItem

const CheckMenuItem = GtkCheckMenuItem

Gtk.@g_type_delegate CheckMenuItem = GtkCheckMenuItem

GtkCheckMenuItem() = GtkCheckMenuItem(ccall((:gtk_check_menu_item_new, Gtk.libgtk), Ptr{GObject}, ()))

GtkCheckMenuItem(title::String) = GtkCheckMenuItem(ccall((:gtk_check_menu_item_new_with_label,Gtk.libgtk),Ptr{GObject},(Ptr{UInt8},),string(title)))

Gtk.@gtktype GtkRadioMenuItem

const RadioMenuItem = GtkRadioMenuItem

Gtk.@g_type_delegate RadioMenuItem = GtkRadioMenuItem

GtkRadioMenuItem(group::Ptr{Void} = C_NULL) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new, Gtk.libgtk), Ptr{GObject}, (Ptr{Void},),group))

GtkRadioMenuItem(label::String) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new_with_mnemonic,Gtk.libgtk),Ptr{GObject},(Ptr{Void},Ptr{UInt8}),C_NULL,string(label)))

GtkRadioMenuItem(group::GtkRadioMenuItem,title::String) = GtkRadioMenuItem(ccall((:gtk_radio_menu_item_new_with_label_from_widget,Gtk.libgtk),Ptr{GObject},(Ptr{GObject},Ptr{UInt8}),group,string(title)))

set_active!(group::GtkRadioMenuItem) = ccall((:gtk_check_menu_item_set_active,Gtk.libgtk),Void,(Ptr{GObject},Bool),group,true)
