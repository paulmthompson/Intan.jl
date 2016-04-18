#=
4 target center out

Graphics Library(ies):
Cairo

States:
1) Start
2) In center
3) Target appears
4) Enter target
5) Hold time achieved (success)
6) Reward
7) End
8) Fail

Target locations:
0, 90, 180, 270 degrees

Target and cursor are circles

=#

export Task_COT

#=
Data structure for 4 target center out
=#
type Task_COT <: Task
    win_t::Gtk.GtkWindowLeaf#task Window handle
    c1::Gtk.GtkCanvasLeaf#task canvas handle
    win_c::Gtk.GtkWindowLeaf#control window handle
    tar::NTuple{2,Float64} #Target location
    success::Int64 #total successes
    total::Int64 #total trials
    state::Int64 #current state
    hold_time::Float64 #hold time
    juice_amount::Float64
    cursor_size::Float64
    target_size::Float64
    reach_radius::Float64
    it_time::Float64 #iter-trial interval
end

#=
Constructors
=#

function Task_COT()

    #Draw Task Screen
    c1=@Canvas(800,800)
    @guarded draw(c1) do widget
    ctx = getgc(c1)
    set_source_rgb(ctx,0,0,0)
    paint(ctx)
    end
    show(c1)
    grid1 = @Grid()
    push!(grid1,c1)
    win1 = @Window(grid1,"Center Out Task")
    showall(win1)

    #Draw Control widget
    grid2 = @Grid()
    button_start=@Button("Start Task")
    grid2[1,1]=button_start
    win2 = @Window(grid2,"Center Out Control")
    showall(win2)

    hold_time=300.0
    juice_amount=1.0
    cursor_size=5.0
    target_size=5.0
    reach_radius=5.0
    it_time=1.0

    Task_COT(win1,c1,win2,(1.0,0.0),0,0,0,hold_time,juice_amount,cursor_size,target_size,reach_radius,it_time)
end

#=
This will create any additional GUIs necessary for experimental control

=#
function init_task(myt::Task_COT,rhd::RHD2000)

    

end

function do_task(myt::Task_COT,rhd::RHD2000)
    
    #Task logic

    #Check if total time has exceeded threshold
    
    if myt.state==1
        
    elseif myt.state==2
        #Determine if in center
        #If time > x, then progress to state=3, make target appear
        #if time < x, then continue waiting
    elseif myt.state==3
        #check if in target, if yes then progress to state=4
    elseif myt.state==4
        #determine if in target
        #if time > x, then progress to state 5
        #if time < x, then continue waiting

        #if outside target, go back to state 3
    elseif myt.state==5
        #If time > x, deliver reward, go to 6
    elseif myt.state==6
        #if time > it_time go to 7
    elseif myt.state==7

    else

    end
    nothing
end

function save_task(myt::Task_COT,rhd::RHD2000)


end

#=
GUI callbacks
=#

