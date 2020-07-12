

function _make_digital_output()



end

function ttl_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.b["digital_out_window"],true)
    nothing
end
