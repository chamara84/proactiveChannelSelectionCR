
function [channelIndex,reward] = rewardCalcForChannel(channelIndex,current_slot,senseResult,senseTime,channelTransitionMat,stationProb,falseAlarm,missedDet, bufferSize, channelAcqProb, pktTrProb)
%vector order [busy;idle]
%transitionMatrix order = [11,10;
%                          01,00]

Q = 1000;
%% initial Vector at sensing time Building
if senseResult == 1 %channel sensed busy
    tau_chanState = [(1-missedDet)*stationProb(1,1);1-(1-missedDet)*stationProb(1,1)]; % channel state Prob vector if Busy
    tau = tau_chanState'*channelTransitionMat^(current_slot-senseTime); % initial vector at current time
elseif senseResult == 0 %sensed idle
    tau_chanState = [1-(1-falseAlarm)*stationProb(2,1);(1-falseAlarm)*stationProb(2,1)];% channel state Prob vector if idle
    tau = tau_chanState'*channelTransitionMat^(current_slot-senseTime); % initial vector at current time
else
    tau = stationProb;% initial vector at current time
end
tau 
tau = [tau';zeros(2*bufferSize-2,1)]';

%% Transition Matrix building for my scheme

T = zeros(2*bufferSize);
T_D = zeros(2*bufferSize);
T_U = zeros(2*bufferSize);

A_0 = [0,0; (1-pktTrProb)*channelAcqProb*channelTransitionMat(2,1)*(1-falseAlarm),(1-pktTrProb)*channelAcqProb*channelTransitionMat(2,2)*(1-falseAlarm)];

A_1 = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
        pktTrProb*channelAcqProb*(1-falseAlarm)*channelTransitionMat(2,1)+(1-pktTrProb)*(1-channelAcqProb)*channelTransitionMat(2,1)*(1-falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,1)*falseAlarm,pktTrProb*channelAcqProb*(1-falseAlarm)*channelTransitionMat(2,2)+(1-pktTrProb)*(1-channelAcqProb)*channelTransitionMat(2,2)*(1-falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,2)*falseAlarm];
    
A_2 = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
       pktTrProb*(1-channelAcqProb)*(1-falseAlarm)*channelTransitionMat(2,1)+pktTrProb*falseAlarm*channelTransitionMat(2,1),pktTrProb*(1-channelAcqProb)*(1-falseAlarm)*channelTransitionMat(2,2)+pktTrProb*falseAlarm*channelTransitionMat(2,2)];

%% reward of trnsmission
A_0_D = [0,0; (1-pktTrProb)*channelAcqProb*channelTransitionMat(2,1)*(1-falseAlarm),(1-pktTrProb)*channelAcqProb*channelTransitionMat(2,2)*(1-falseAlarm)];
A_1_D =[0,0;0,0];
A_2_D  =[0,0;0,0];
%% cost of failing to transmit
A_0_U =[0,0;0,0];
A_1_U = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
        (1-pktTrProb)*(1-channelAcqProb)*channelTransitionMat(2,1)*(1-falseAlarm),(1-pktTrProb)*(1-channelAcqProb)*channelTransitionMat(2,2)*(1-falseAlarm)];   
A_2_U = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
       pktTrProb*(1-channelAcqProb)*(1-falseAlarm)*channelTransitionMat(2,1),pktTrProb*(1-channelAcqProb)*(1-falseAlarm)*channelTransitionMat(2,2)];   

   
T(1:2,1:2) = A_1;
T(1:2,3:4) = A_2;
T((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0;
T((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1+A_2;

T_D(1:2,1:2) = A_1_D;
T_D(1:2,3:4) = A_2_D;
T_D((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0_D;
T_D((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1_D+A_2_D;

T_U(1:2,1:2) = A_1_U;
T_U(1:2,3:4) = A_2_U;
T_U((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0_U;
T_U((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1_U+A_2_U;




for row = 3:2:(2*bufferSize-3)
            T(row:row+1,(row-2):(row-1)) = A_0;
            T(row:row+1,row:row+1) = A_1; 
            T(row:row+1,(row+2):(row+3)) = A_2;
            
            T_D(row:row+1,(row-2):(row-1)) = A_0_D;
            T_D(row:row+1,row:row+1) = A_1_D; 
            T_D(row:row+1,(row+2):(row+3)) = A_2_D;
            
            T_U(row:row+1,(row-2):(row-1)) = A_0_U;
            T_U(row:row+1,row:row+1) = A_1_U; 
            T_U(row:row+1,(row+2):(row+3)) = A_2_U;
end
sum(T,2)

%% absorption vector
T_0 = [0;(1-pktTrProb)*channelAcqProb*(channelTransitionMat(2,1)+channelTransitionMat(2,2)*(1-falseAlarm));zeros(2*bufferSize-2,1)];


cumProb = 0;
reward = 0;
n = 1;
while  n< Q   %%cumProb <0.95 &&
    %prob = tau*T^n*T_0;
    prob = T^n*T_0;
    %cumProb = cumProb + prob;
    %reward = reward + n*prob;
    reward = reward + prob;
    n = n+1;

end
reward
tau*reward
Exp_U = 0;
Exp_D = 0;


tempSumOuter_D = 0;

tempSumOuter_U = 0;

for iteration = 1:(Q-1)
    
   
    tempSumInner_D = 0;
    tempSumInner_U = 0;
    for innerIteration = 1:(iteration-1)
        before = T^(innerIteration-1);
        after =  T^(iteration-innerIteration-1)*T_0;
          tempSumInner_D = tempSumInner_D + before*T_D*after;
          tempSumInner_U = tempSumInner_U + before*T_U*after;
    end
    tempSumOuter_D = tempSumOuter_D +tempSumInner_D;
    tempSumOuter_U =  tempSumOuter_U +tempSumInner_U;
end
tau*tempSumOuter_D
tau*tempSumOuter_U
end


