module Center_Out_Test

using Intan, FactCheck

m=Task_COT()

facts() do
    @fact m.tar --> (1.0,0.0)
    @fact m.success --> 0
    @fact m.total --> 0
    @fact m.state --> 0
    @fact m.hold_time --> 300.0
    @fact m.juice_amount --> 1.0
    @fact m.cursor_size --> 5.0
    @fact m.target_size --> 5.0
    @fact m.reach_radius --> 5.0
    @fact m.it_time --> 1.0
end


end
