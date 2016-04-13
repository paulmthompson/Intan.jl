module Gui_Test

using FactCheck, Intan, SpikeSorting

myamp=RHD2164("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myrhd=makeRHD(myamp,"single",debug=d)

handles = makegui(myrhd)

facts() do

    @fact handles.mi --> (0.0,0.0)
    
end

end
