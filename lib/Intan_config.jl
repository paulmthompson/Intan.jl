
myamp=RHD2164("PortA1")

myfpga=FPGA(1,myamp)

mt=Task_NoTask()

mys=SaveNone()

(myrhd,sss,fpgas)=makeRHD([myfpga],sav=mys)

handles=makegui(myrhd,sss,mt,fpgas)
