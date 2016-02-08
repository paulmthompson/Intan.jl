module Board_Test

using Intan, FactCheck

myamp=RHD2164("PortA1")

facts() do
    @fact myamp --> [0,8]
end

end
