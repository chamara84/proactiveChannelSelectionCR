function T = numControlSlotsProb(numSU,probAvail,falarmProb,slotNum,numPU)
 S = 1;
 T =0;
 T0 = 1;
 %disp(slotNum)
 
 
 
 if slotNum <= numPU
    for rotate =1:numPU
        T0=1;
        probAvail = circshift(probAvail,[0,1]);
        for i = 1:(slotNum-1)
            T0 = T0*((1-probAvail(1,i))+probAvail(1,i)*((1-1/(numSU*0.6))*(1-falarmProb)+falarmProb) );
        end
        T0 = T0*probAvail(1,slotNum)*(1-falarmProb)/(numSU*0.6);
       T = T+T0*1/numPU; 
    end
else
    for i = 1:(numPU)
        S = S*((1-probAvail(1,i))+probAvail(1,i)*((1-1/(numSU*0.6))*(1-falarmProb)+falarmProb) );
    end
    S = S^(floor((slotNum-1)/numPU));
    
    for rotate =1:numPU
        T0=1;
        probAvail = circshift(probAvail,[0,1]);
        for i = 1:(mod(slotNum-1,numPU))
            T0 = T0*((1-probAvail(1,i))+probAvail(1,i)*((1-1/(numSU*0.6))*(1-falarmProb)+falarmProb) );
        end
        T = T+T0*1/numPU;
    end
    
    T = S*T*probAvail(1,mod(slotNum-1,numPU)+1)*(1-falarmProb)/(numSU*0.6);
end
end
