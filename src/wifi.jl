

function udp_listener()

    bind(udpsock,ip"192.168.1.100",2000)

    buffer=zeros(UInt8,100000)
    
    @spawnat 3 getpacket(buffer)

end

function getpacket(buffer)
    
    myoff=0
    wifi_v[1,21,1]=1

    while true
        buffer[1:(30*2*20)]=recv(udpsock)

        index=1

        for i=1:size(wifi_v,2)-1
            for j=1:30
                x1=convert(UInt16,buffer[index])
                x2=convert(UInt16,buffer[index+1])

                wifi_v[j+myoff,i,wifi_v[1,21,1]]=convert(Int16,signed((x2<<8)|x1)-typemax(Int16))
                index+=2
            end
        end

        myoff+=30

        if myoff>=600
            myoff=0
            wifi_v[1,21,1] = !wifi_v[1,21,1]
        end
    end
    nothing
end
