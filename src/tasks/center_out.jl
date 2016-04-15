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

#=
Data structure for 4 target center out
=#
type Task_COT <: Task
    tar::NTuple{2,Float64} #Target location
    success::Int64
    total::Int64
    state_cur::Int64
end

#=
This will create any additional GUIs necessary for experimental control

=#
function init_task(myt::Task_COT,rhd::RHD2000)

    

end

function do_task(myt::Task_COT,rhd::RHD2000)

    #Task logic
    if myt.start_cur==1
        
    elseif myt.start_cur==2

    elseif myt.start_cur==3

    elseif myt.start_cur==4

    elseif myt.start_cur==5

    elseif myt.start_cur==6

    elseif myt.start_cur==7

    else

    end
        
end

function save_task(myt::Task_COT,rhd::RHD2000)


end
