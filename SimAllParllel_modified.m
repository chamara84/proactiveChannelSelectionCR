clear all
clc
%matlabpool open 

for indexprobSUChanAcc= 2:9
   
    numIterations = 2;
    numberOfSUs = 20; % change in other files too
   SUAccessProb = 0.1*indexprobSUChanAcc;
    interferenceVec = zeros(numIterations,2);
    controlSlotsVec = zeros(numIterations,2);
    throughPutVec = zeros(numIterations,2);
    SUUsingSameChanVec = zeros(numIterations,2);
for algorithm = 1:2
    
    multiUserSim =[];
    
    parfor iteration =  1:numIterations
                
        multiUserSim = [multiUserSim, multiUserPredictiveChannelUse(algorithm, SUAccessProb)];
            
    end
    
    for i = 1:numIterations
            [interferenceVec(i,algorithm),throughPutVec(i,algorithm) ,controlSlotsVec(i,algorithm),SUUsingSameChanVec(i,algorithm) ] = multiUserSim(1,i).audit(numberOfSUs);
                                    
    end
        
        
   
end
 save(strcat('MAP',num2str(SUAccessProb),'pm_Utilization.mat'),'interferenceVec','controlSlotsVec','throughPutVec','SUUsingSameChanVec');
end