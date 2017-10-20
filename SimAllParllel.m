clear all
clc
%matlabpool open 

for indexprobMissed= 1:5
    numIterations = 3;
    numberOfSUs = 20; % change in other files too
    probMissed = 0.1*indexprobMissed;
   
    interferenceVec = zeros(numIterations,2);
    controlSlotsVec = zeros(numIterations,2);
    throughPutVec = zeros(numIterations,2);
    SUUsingSameChanVec = zeros(numIterations,2);
    
    for iteration =  1:numIterations
        multiUserSim =[];
        
        interference = zeros(1,2);
        controlSlots = zeros(1,2);
        throughPut= zeros(1,2);
        SUUsingSameChan = zeros(1,2);
        parfor i=1:2
            multiUserSim = [multiUserSim, multiUserPredictiveChannelUse(i, probMissed)];
            
        end
        for index = 1:2
            [interference(1,index),throughPut(1,index),controlSlots(1,index),SUUsingSameChan(1,index)] = multiUserSim(1,index).audit(obj,numberOfSUs);
                                    
        end
        
        interferenceVec(iteration,:) = interference(1,:) ;
        controlSlotsVec(iteration,:) = controlSlots(1,:);
        throughPutVec(iteration,:) = throughPut(1,:);
        SUUsingSameChanVec(iteration,:) = SUUsingSameChan(1,:);
      
        
    end
    save(strcat('MAP',num2str(probMissed),'pm.mat'),'interferenceVec','controlSlotsVec','throughPutVec','SUUsingSameChanVec');
end