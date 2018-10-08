
module Stress_Test

using Intan,SpikeSorting,Gtk.ShortNames, Cairo

function stress_init(amps)
    d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
    myt=Task_NoTask()
    rhd=makeRHD(amps,myt,debug=d)
    handles = makegui(rhd)
    (rhd,handles)
end

function stress_test(myrhd,handles)

    Intan.init_cb(handles.init.handle,(handles,myrhd));

    myctx=getgc(handles.c)
    myctx2=getgc(handles.c2)

    #calibrate
    for i=1:1000
        Intan.main_loop(myrhd,handles,myctx,myctx2)
    end

    setproperty!(handles.cal,:active,false)
    Intan.cal_cb(handles.cal.handle,(handles,myrhd))
    mytimes=zeros(Float64,1000)

    for i=1:1000
        mytimes[i]=@elapsed Intan.main_loop(myrhd,handles,myctx,myctx2)
    end
    destroy(handles.win)
    mytimes
end

function total_test(amps)
    sleep(1.0)
    (myrhd,myhandles)=stress_init(amps)
    sleep(1.0)
    stress_times=stress_test(myrhd,myhandles)
end

function perform_test()
    st=zeros(Float64,8)

    myamp=RHD2132("PortA1")
    st[1]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortA2"))
    st[2]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortB1"))
    st[3]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortB2"))
    st[4]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortC1"))
    st[5]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortC2"))
    st[6]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortD1"))
    st[7]=mean(total_test(myamp))

    append!(myamp,RHD2132("PortD2"))
    st[8]=mean(total_test(myamp))


    #normalize
    st=st./(Intan.SAMPLES_PER_DATA_BLOCK/30000)
    println(st)

end

end
