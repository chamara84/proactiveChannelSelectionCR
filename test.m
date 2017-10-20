clear;
channelIndex = 1;
current_slot=1;
senseResult = 0;
senseTime = 1;
channelTransitionMat = [0.2,0.8;0.2,0.8];
A = channelTransitionMat-eye(2);
A = [A;1,1];
b = [0;0;1];

stationProb = A\b;
falseAlarm = 0.1;
missedDet= 0.2; 
bufferSize = 10; 
channelAcqProb = 0.4; 
pktTrProb = 0.1;
[channelIndex,reward] = rewardCalcForChannel(channelIndex,current_slot,senseResult,senseTime,channelTransitionMat,stationProb,falseAlarm,missedDet, bufferSize, channelAcqProb, pktTrProb);