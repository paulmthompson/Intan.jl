#=
Cairo drawing helper functions
=#

#=
Backgrounds
=#
function black_bg(ctx::CairoContext)
    set_source_rgb(ctx,0,0,0)
    paint(ctx)
    nothing
end

function white_bg(ctx::CairoContext)
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
    nothing
end

#=
Draw Shapes
=#
function draw_circle(xi::Float64,xnew::Float64,yi::Float64,ynew::Float64,ctx::CairoContext)
    draw_circle(xi,xnew,yi,ynew,50.0,ctx)  
end

function draw_circle(xi::Float64,xnew::Float64,yi::Float64,ynew::Float64,r::Float64,ctx::CairoContext)

    set_line_width(ctx, 9)
    set_source_rgb(ctx, 1.0, 1.0, 1.0)
    translate(ctx, (xnew-xi)/2, (ynew-yi)/2)
    arc(ctx, 0, 0, r, 0, 2 * pi)
    stroke_preserve(ctx)
    set_source_rgb(ctx, 1.0, 1.0, 1.0)
    fill(ctx)
    nothing
end

