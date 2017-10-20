classdef SecondaryUser < handle
    %memory length fixed at 10
    properties (Access = public)
        isTransmiting % 1 if needs to transmit 0 otherwise
        SUIndex %SU index
        channelAcquired % index of channel acquired 
        isHandshakeDone % 1 if done 0 if not
        channelsSensed % a matrix having sensing result in columns and channel
        numPacketsToTx % the number of packets left to transmit
        pktsTranmitted %number of packets already transmitted
        channelSwitchOrder % the order in which channels are hopped
        defaultSwitchOrder % control phase channel switch order
        currentAttempt %the try number
        currentAttemptCtrl % control try number
        falseAlarm
        missedDetection
        pstModel % PST prediction model
        hmmModel %HMM prediction model
        meanIdleDuration % mean idle durations of channels
        ab %alphabet
        memoryLengthUsed % the number of past slots used for prediction
        cumulativeCtrlSlots % array of the number of control slots
        cumulativeTxslots % array of the number of transmit slots spent
        cumulativePackets %array of the number of packets transmitted
        cumulativeInterferedSlots % array of sub slots interfered 
        cumulativeCollisionSlots % an array of the number of collisions happened
        channelAccessMemory % memory of past Q channel accesses [numberof tries,successes]
        PUChannelAccess % sensed information about the promary user activity [state, slotNum]
        %timeSlotNum % the time slot number
        rewardVec %reward vec for each channel
        channelActivitySU % prababilty of aquiring the channel
        initialVec %initial vector for all channels
        P %channel transition matrix
        P_0 %stationary probability of channel being idle
        P_1 %stationary probability of channel being busy
        rewardCalculated %1 if the reward has been calculated else 0
    end
    
    properties(Access = private)
        
    end
    
    methods
        function obj = SecondaryUser(SUIndex,ctrlSwitchOrder,falseAlarm, missedDetection,pstModel,hmmModel,meanIdleDuration,numPUs)
            obj.isTransmiting = 0;
            obj.SUIndex = SUIndex;
            obj.channelAcquired = 0;
            obj.isHandshakeDone = 0;
            obj.channelsSensed = [];
            obj.numPacketsToTx = 0; % no channel allocated
            obj.pktsTranmitted = 0;
            obj.channelSwitchOrder = [];
            obj.defaultSwitchOrder = ctrlSwitchOrder ; 
            obj.currentAttempt = 0;
            obj.currentAttemptCtrl = 0;
            obj.falseAlarm =falseAlarm;
            obj.missedDetection = missedDetection;
            obj.pstModel= pstModel;
            obj.hmmModel = hmmModel;
            obj.meanIdleDuration= meanIdleDuration;
            obj.ab = alphabet('10');
            obj.memoryLengthUsed = 10;
            obj.cumulativeCtrlSlots = [];
            obj.cumulativeTxslots  = [];
            obj.cumulativePackets = [];
            obj.cumulativeInterferedSlots = 0;
            obj.cumulativeCollisionSlots = 0;
            obj.channelAccessMemory = zeros(numPUs,2);
            obj.PUChannelAccess = [ones(numPUs,1),zeros(numPUs,1)]*3;
            obj.rewardVec = [];
            obj.initialVec = [];
            obj.channelActivitySU = [];
            obj.rewardCalculated = 0;
            obj.P = cell(3,1);
            obj.P_0 = cell(3,1);
            obj.P_1 =cell(3,1);
            for utilIndex = 1:3
                obj.P{utilIndex,1}(1,1) =  vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'1'),map(obj.ab,'1'));
                obj.P{utilIndex,1}(1,2) =  vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'0'),map(obj.ab,'1'));
                obj.P{utilIndex,1}(2,1) =  vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'1'),map(obj.ab,'0'));
                obj.P{utilIndex,1}(2,2) =  vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'0'),map(obj.ab,'0'));
                
                obj.P_0{utilIndex,1} = vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'0'),'');
                obj.P_1{utilIndex,1} = vmm_getPr(obj.pstModel{utilIndex,1},map(obj.ab,'1'),'');
                
            end
        end
        
        function  acquireChannel(obj,IndexCapChan,numSwitches,numChannels,numberSU,pktTxProb,sizeSUBuff,slotNumber,algorithmIndex)
            
            captureChannelIndex = IndexCapChan;
            numChannelsSUAccessPerSlot = numSwitches;
            numPU= numChannels;
            numSU = numberSU;
            probPktTx = pktTxProb;
            bufferSize=sizeSUBuff;
            current_slot = slotNumber;
            algorithm = algorithmIndex;
            
            
            if obj.isHandshakeDone == 0 && obj.isTransmiting == 1
                
                obj.channelsSensed = [];
                obj.currentAttemptCtrl =obj.currentAttemptCtrl+1;
                
                if algorithm ==1
                    additionalChanSense = obj.findChannelsToSense(numPU,numSU,probPktTx,bufferSize,current_slot,numChannelsSUAccessPerSlot);
                    if isempty(find(additionalChanSense==captureChannelIndex,1))==1
                        obj.channelsSensed = [captureChannelIndex;additionalChanSense(1:(numChannelsSUAccessPerSlot-1),1)];
                    else
                        obj.channelsSensed = additionalChanSense;
                    end
                    obj.channelsSensed = sort(obj.channelsSensed);
                elseif algorithm ==2
                    additionalChanSense = randperm(numPU)';
                    additionalChanSense = additionalChanSense(1:numChannelsSUAccessPerSlot,1);
                    if isempty(find(additionalChanSense==captureChannelIndex,1))==1
                        obj.channelsSensed = [captureChannelIndex;additionalChanSense(1:(numChannelsSUAccessPerSlot-1),1)];
                    else
                        obj.channelsSensed = additionalChanSense;
                    end
                    obj.channelsSensed = sort(obj.channelsSensed);
                else
                    if captureChannelIndex < numChannelsSUAccessPerSlot
                        obj.channelsSensed = [1:captureChannelIndex,(numPU-(numChannelsSUAccessPerSlot-captureChannelIndex)+1):numPU]';
                    else
                        obj.channelsSensed = (1:numChannelsSUAccessPerSlot)';
                    end
                    
                end
                     
                        
            elseif obj.isHandshakeDone == 1 && obj.isTransmiting == 1
                
                obj.currentAttempt =obj.currentAttempt+1;
                
            end
                
            
        end
        
        function  additionalChanSense =findChannelsToSense(obj,numPU,numSU,probPktTx,bufferSize,current_slot,numChannelsSUAccessPerSlot)
            Q= 100;
            
            
            %if mod(current_slot-1,Q)==0 || obj.rewardCalculated == 0
                obj.rewardCalculated = 1;
                obj.calcChannelActivity(numSU,probPktTx,numPU);
                obj.calcRewardVecAllChannels(bufferSize,probPktTx,Q);
            %end
            
            obj.initialVectorCalc(current_slot,bufferSize);
            
            reward = zeros(numPU,1);
            
            
            for channelIndex = 1:numPU
                reward(channelIndex,1) = obj.initialVec(channelIndex,1:2*bufferSize)*obj.rewardVec(1:2*bufferSize,channelIndex)-obj.initialVec(channelIndex,(2*bufferSize+1):end)*obj.rewardVec((2*bufferSize+1):end,channelIndex);
            end
            [~,sensedChannels] = sort(reward,'descend');
            %disp(sensedChannels);
            additionalChanSense = sensedChannels(1:numChannelsSUAccessPerSlot,1);
            
           
%             if captureChannelIndex < numChannelsSUAccessPerSlot
%                         obj.channelsSensed = [1:captureChannelIndex,(numPU-(numChannelsSUAccessPerSlot-captureChannelIndex)+1):numPU]';
%             else
%                         obj.channelsSensed = (1:numChannelsSUAccessPerSlot)';
%             end
            
        end
        
        function transmit(obj,numPackets)
%            disp('SU index');
%            disp(obj.SUIndex);
            
            
            if  (obj.numPacketsToTx <= 0 && obj.isTransmiting == 1)
%                 disp('SU index');
%                 disp(obj.SUIndex);
%                 disp('Number of Control Attempts');
%                 disp(obj.currentAttemptCtrl);
%                 disp('Number of Tx Attempts');
%                 disp(obj.currentAttempt);
%                 disp('Number of pkts Txed');
%                 disp(obj.pktsTranmitted);
                
                obj.cumulativeCtrlSlots = [obj.cumulativeCtrlSlots,obj.currentAttemptCtrl];
%                 obj.cumulativeTxslots  = [obj.cumulativeTxslots,obj.currentAttempt];
%                 obj.cumulativePackets = [obj.cumulativePackets,obj.pktsTranmitted];
                obj.isTransmiting = 0;
                obj.channelAcquired = 0;
                obj.isHandshakeDone = 0;
                obj.channelsSensed = [];
                obj.numPacketsToTx = 0;
                %obj.pktsTranmitted = 0;
                obj.channelSwitchOrder = [];
               % obj.currentAttempt = 0;
                obj.currentAttemptCtrl = 0;
               
            elseif obj.numPacketsToTx > 0 && obj.isTransmiting == 1
                obj.numPacketsToTx = obj.numPacketsToTx  -1;
                obj.pktsTranmitted =obj.pktsTranmitted+1;
            end
        end
        
        function sense(obj,puChannelStates,slotIndex)
           
            tempChannelStates =zeros(size(obj.channelsSensed,1),1);
            tempChannelStates2 =zeros(size(obj.channelsSensed,1),1);
            for i=1:size(obj.channelsSensed,1)
                if puChannelStates(obj.channelsSensed(i,1),1) == '0'
                    randomNum = rand();
                   if randomNum <=obj.falseAlarm
                       tempChannelStates(i,1)= '1';
                   else
                       tempChannelStates(i,1)= '0';
                   end
                   randomNum = rand();
                   if randomNum<=obj.falseAlarm
                       tempChannelStates2(i,1)= '1';
                   else
                       tempChannelStates2(i,1)= '0';
                   end
                       
                else 
                   randomNum = rand();
                    if randomNum<= obj.missedDetection
                       tempChannelStates(i,1) = '0';
                       
                   else
                       tempChannelStates(i,1) = '1';
                       
                    end
                    randomNum = rand();
                    if randomNum<= obj.missedDetection
                       tempChannelStates2(i,1) = '0';
                       
                   else
                       tempChannelStates2(i,1) = '1';
                       
                    end
                   
               end
               if  tempChannelStates2(i,1)+tempChannelStates(i,1) == '0'+'0'
                   tempChannelStates(i,1) = '0';
               else
                   tempChannelStates(i,1) = '1';
               end
            end
            
            
            if size(obj.channelsSensed,2) == obj.memoryLengthUsed + 1
                
                obj.channelsSensed(:,2) =[];
                obj.channelsSensed = [obj.channelsSensed,tempChannelStates];
            else
                obj.channelsSensed = [obj.channelsSensed,tempChannelStates];
            end
            
%             if size(obj.PUChannelAccess,2) == 1000 + 1 % hardcoded the value of the memory kept to be 1000
%                 
%                 obj.PUChannelAccess(:,1) =[];
%                 memSlot = size(obj.PUChannelAccess,2); 
%                 obj.PUChannelAccess(1,memSlot+1) = slotIndex;
%                 for chanIndex = 2:(size(puChannelStates,1)+1)
%                     if isempty(find(obj.channelsSensed(:,1)==(chanIndex-1), 1))==1
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = 3;
%                     else
%                         %display(find(obj.channelsSensed(:,1)==(chanIndex-1),1));
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = tempChannelStates(find(obj.channelsSensed(:,1)==(chanIndex-1),1),1);
%                         
%                     end
%                 end
%             else
                
                for chanIndex = 1:(size(puChannelStates,1))
                    indexOfChan = find(obj.channelsSensed(:,1)==chanIndex);
                    if isempty(indexOfChan)~=1
                         obj.PUChannelAccess(chanIndex,1) = tempChannelStates(indexOfChan,1);
                        obj.PUChannelAccess(chanIndex,2) = slotIndex;
                    
                    end
                end
%             end
        end
        
        function predict(obj,algorithm,buffSize,slotIndex)
            bufferSize = buffSize;
            current_slot = slotIndex;
            probability_idle = zeros(size(obj.channelsSensed,1),1);
            prediction_HMM = zeros(2,1);
            if algorithm ==1 || algorithm ==2
            for i=1:size(obj.channelsSensed,1)
                if obj.channelsSensed(i,1) <= 4
                    
                    if size(obj.channelsSensed,2) ==1
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{1,1},map(obj.ab,'0'),'')*obj.meanIdleDuration(1,obj.channelsSensed(i,1))*obj.channelActivitySU(obj.channelsSensed(i,1),1); %(obj.channelsSensed(i,1),1) ;
                    else
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{1,1},map(obj.ab,'0'),map(obj.ab,obj.channelsSensed(i,2:end)))*obj.meanIdleDuration(1,obj.channelsSensed(i,1))*obj.channelActivitySU(obj.channelsSensed(i,1),1); %(obj.channelsSensed(i,1),1) ;
                    end
                elseif obj.channelsSensed(i,1) > 4 &&  obj.channelsSensed(i,1) <= 8
                    if size(obj.channelsSensed,2) ==1
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{2,1},map(obj.ab,'0'),'')*obj.meanIdleDuration(1,obj.channelsSensed(i,1))*obj.channelActivitySU(obj.channelsSensed(i,1),1); %(obj.channelsSensed(i,1),1) ;
                    else
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{2,1},map(obj.ab,'0'),map(obj.ab,obj.channelsSensed(i,2:end)))*obj.meanIdleDuration(1,obj.channelsSensed(i,1))*obj.channelActivitySU(obj.channelsSensed(i,1),1); %(obj.channelsSensed(i,1),1) ;
                    end
                elseif obj.channelsSensed(i,1) > 8 &&  obj.channelsSensed(i,1) <= 10
                    if size(obj.channelsSensed,2) ==1
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{3,1},map(obj.ab,'0'),'')*obj.meanIdleDuration(1,obj.channelsSensed(i,1)); %(obj.channelsSensed(i,1),1) ;
                    else
                        probability_idle(i,1) = vmm_getPr(obj.pstModel{3,1},map(obj.ab,'0'),map(obj.ab,obj.channelsSensed(i,2:end)))*obj.meanIdleDuration(1,obj.channelsSensed(i,1))*obj.channelActivitySU(obj.channelsSensed(i,1),1); %(obj.channelsSensed(i,1),1) ;
                    end
                end
                
            end
            [~, index_Alg] = sort(probability_idle,'descend');
                   
            obj.channelSwitchOrder = obj.channelsSensed(index_Alg,1);
            elseif algorithm == 6
                for i=1:size(obj.channelsSensed,1)
                    past_d_slot_hmm = obj.channelsSensed(i,2:end)-47;
                    prediction_HMM(1,1) =  dhmm_logprob([past_d_slot_hmm, 1], obj.hmmModel.prior_final1, obj.hmmModel.transmat_final1, obj.hmmModel.obsmat_final1);
                    prediction_HMM(2,1) =  dhmm_logprob([past_d_slot_hmm, 2], obj.hmmModel.prior_final1, obj.hmmModel.transmat_final1, obj.hmmModel.obsmat_final1);
                    probability_idle(i,1)= prediction_HMM(1,1)- prediction_HMM(2,1);
                end
                
                [~, index_Alg] = sort(probability_idle,'descend');
                   
                obj.channelSwitchOrder = obj.channelsSensed(index_Alg,1);
                
            elseif algorithm == 3 %predict using the transition matrix
                
                obj.initialVectorCalc(current_slot,bufferSize);
                               
               probability_idle(:,1) =obj.initialVec(:,2) ;
                 
                [~, index_Alg] = sort(probability_idle,'descend');
                   
                obj.channelSwitchOrder = obj.channelsSensed(index_Alg,1);
                
            elseif algorithm == 4 %random order
               index_Alg = randperm(size(obj.channelsSensed,1));
                      
               obj.channelSwitchOrder = obj.channelsSensed(index_Alg,1);
               
            elseif algorithm == 5 %our new algorithm
               
                
                obj.initialVectorCalc(current_slot,bufferSize)
                for i=1:size(obj.channelsSensed,1)
                   
                        
                        tempPrbVec = obj.initialVec(obj.channelsSensed(i,1),1:2*bufferSize)*obj.rewardVec(1:(2*bufferSize),obj.channelsSensed(i,1)) - obj.initialVec(obj.channelsSensed(i,1),1:2*bufferSize)*obj.rewardVec((2*bufferSize+1):end,obj.channelsSensed(i,1));
                        probability_idle(i,1) =tempPrbVec ; %(obj.channelsSensed(i,1),1) ;
                    
                end
                [~, index_Alg] = sort(probability_idle,'descend');
                   
                obj.channelSwitchOrder = obj.channelsSensed(index_Alg,1);
            end          
            
            
        end
        
        function channelState = senseOne(obj,puChannelStates,channelNum,slotIndex)
           
            
            if puChannelStates(channelNum,1) == '0'
                randomNum = rand();
                if randomNum <=obj.falseAlarm
                    channelState = '1';
                else
                    channelState = '0';
                end
                
            else
                randomNum = rand();
                if randomNum <= obj.missedDetection
                    channelState = '0';
                    
                else
                    channelState = '1';
                    
                end
            end
            
                         
                   
            obj.PUChannelAccess(channelNum,1) = channelState;
            obj.PUChannelAccess(channelNum,2) = slotIndex;
                    
                    
            
%             if size(obj.PUChannelAccess,2) >= 1000 % hardcoded the value of the memory kept to be 1000
%                 
%                 obj.PUChannelAccess(:,1) =[];
%                 memSlot = size(obj.PUChannelAccess,2); 
%                 obj.PUChannelAccess(1,memSlot+1) = slotIndex;
%                 for chanIndex = 2:(size(puChannelStates,1)+1)
%                     if chanIndex == channelNum+1
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = channelState;
%                     else
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = 3;
%                     end
%                 end
%             else
%                 memSlot = size(obj.PUChannelAccess,2); 
%                 obj.PUChannelAccess(1,memSlot+1) = slotIndex;
%                 for chanIndex = 2:(size(puChannelStates,1)+1)
%                     if chanIndex == channelNum+1
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = channelState;
%                     else
%                         obj.PUChannelAccess(chanIndex,memSlot+1) = 3;
%                         
%                     end
%                 end
%             end
        end
        
        function calcChannelActivity(obj,numSU,probPktTx,numPU)
           
            epsilon = zeros(numPU,1); % probability of channel acquired
%             disp('SUIndex');
%             disp(obj.SUIndex);
%             disp(obj.channelAccessMemory);
            for channelNum = 1:numPU % 
                %1 for not acquired, 0 for acquired, 3 for unsensed
                
                if obj.channelAccessMemory(channelNum,2)~= 0  &&  obj.channelAccessMemory(channelNum,1)~= 0
                    epsilon(channelNum,1) = obj.channelAccessMemory(channelNum,2)/ obj.channelAccessMemory(channelNum,1);
                else
                    epsilon(channelNum,1) = min((numPU/numSU*probPktTx),1);
                end
        
            end

                %epsilon = rand(numPU,1);
                obj.channelActivitySU = epsilon(:,1)/sum(epsilon(:,1));

            


%           disp(sprintf('SUIndex=%f',obj.SUIndex));
%           disp(obj.channelActivitySU);
%          
        end
        
        function calcRewardVecAllChannels(obj,bufferSize, pktTrProb,Q)
            
            %% Transition Matrix building for my scheme
            for channelIndexR = 1:size(obj.channelActivitySU,1)
                if channelIndexR<=4
                    channelTransitionMat = obj.P{1,1};
                elseif channelIndexR > 4 && channelIndexR <= 8
                    channelTransitionMat = obj.P{2,1};
                elseif channelIndexR > 8 && channelIndexR <= 10
                    channelTransitionMat = obj.P{3,1};
                end
                    
                T = zeros(2*bufferSize);
                T_D = zeros(2*bufferSize);
                T_U = zeros(2*bufferSize);
                
                A_0 = [0,0; (1-pktTrProb)*obj.channelActivitySU(channelIndexR,1)*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*obj.channelActivitySU(channelIndexR,1)*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
                
                A_1 = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
                    pktTrProb*obj.channelActivitySU(channelIndexR,1)*(1-obj.falseAlarm)*channelTransitionMat(2,1)+(1-pktTrProb)*(1-obj.channelActivitySU(channelIndexR,1))*channelTransitionMat(2,1)*(1-obj.falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,1)*obj.falseAlarm,pktTrProb*obj.channelActivitySU(channelIndexR,1)*(1-obj.falseAlarm)*channelTransitionMat(2,2)+(1-pktTrProb)*(1-obj.channelActivitySU(channelIndexR,1))*channelTransitionMat(2,2)*(1-obj.falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,2)*obj.falseAlarm];
                
                A_2 = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
                    pktTrProb*(1-obj.channelActivitySU(channelIndexR,1))*(1-obj.falseAlarm)*channelTransitionMat(2,1)+pktTrProb*obj.falseAlarm*channelTransitionMat(2,1),pktTrProb*(1-obj.channelActivitySU(channelIndexR,1))*(1-obj.falseAlarm)*channelTransitionMat(2,2)+pktTrProb*obj.falseAlarm*channelTransitionMat(2,2)];
                
                %% reward of trnsmission
                A_0_D = [0,0; (1-pktTrProb)*obj.channelActivitySU(channelIndexR,1)*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*obj.channelActivitySU(channelIndexR,1)*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
                A_1_D =[0,0;0,0];
                A_2_D  =[0,0;0,0];
                %% cost of failing to transmit
                A_0_U =[0,0;0,0];
                A_1_U = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
                    (1-pktTrProb)*(1-obj.channelActivitySU(channelIndexR,1))*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*(1-obj.channelActivitySU(channelIndexR,1))*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
                A_2_U = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
                    pktTrProb*(1-obj.channelActivitySU(channelIndexR,1))*(1-obj.falseAlarm)*channelTransitionMat(2,1),pktTrProb*(1-obj.channelActivitySU(channelIndexR,1))*(1-obj.falseAlarm)*channelTransitionMat(2,2)];
                
                
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
                
                
                %% absorption vector
                T_0 = [0;(1-pktTrProb)*obj.channelActivitySU(channelIndexR,1)*(channelTransitionMat(2,1)+channelTransitionMat(2,2)*(1-obj.falseAlarm));zeros(2*bufferSize-2,1)];
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
                
                obj.rewardVec(:,channelIndexR) = [tempSumOuter_D;tempSumOuter_U];
                %display(obj.rewardVec(:,channelIndexR))
                
                
                
            end
        end
        
        function initialVectorCalc(obj,current_slot,bufferSize)
            lastsensed = obj.PUChannelAccess; % vector having last sensing result and time stamp
            %channelTransitionMat = obj.P ;%channel transition matrix
                
            stationProb = [obj.P_1;obj.P_0];
            for channelIndex = 1:(size(obj.PUChannelAccess,1))
                if channelIndex<=4
                    channelTransitionMat = obj.P{1,1};
                    stationProb = [obj.P_1{1,1};obj.P_0{1,1}];
                elseif channelIndex > 4 && channelIndex <= 8 %channel transition matrix
                    channelTransitionMat = obj.P{2,1};
                     stationProb = [obj.P_1{2,1};obj.P_0{2,1}];
                elseif channelIndex > 8 && channelIndex <= 10
                    channelTransitionMat = obj.P{3,1};
                     stationProb = [obj.P_1{3,1};obj.P_0{3,1}];
                end
               
                %% initial Vector at sensing time Building
                if lastsensed(channelIndex,1) == '1' %channel sensed busy
                    tau_chanState = [(1-obj.missedDetection )*stationProb(1,1),1-(1-obj.missedDetection )*stationProb(1,1)]; % channel state Prob vector if Busy
                    tau = tau_chanState*channelTransitionMat^(current_slot-lastsensed(channelIndex,2)); % initial vector at current time
                elseif lastsensed(channelIndex,1)  == '0' %sensed idle
                    tau_chanState = [1-(1-obj.falseAlarm)*stationProb(2,1),(1-obj.falseAlarm)*stationProb(2,1)];% channel state Prob vector if idle
                    tau = tau_chanState*channelTransitionMat^(current_slot-lastsensed(channelIndex,2)); % initial vector at current time
                else
                    tau = stationProb';% initial vector at current time
                end
                tau = [tau';zeros(2*bufferSize-2,1)]';
                obj.initialVec(channelIndex,:) = [tau,tau]; 
            end
            
%              disp(sprintf('SUIndex=%f',obj.SUIndex));
%              disp(lastsensed);
            
            
        end
         
%         function [channelIndex,reward] = rewardCalcForChannel(obj,channelIndex,current_slot,senseResult,senseTime,channelTransitionMat,stationProb,obj.missedDetection , bufferSize, pktTrProb)
%             %vector order [busy;idle]
%             %transitionMatrix order = [11,10;
%             %                          01,00]
%             
%             Q = 1000;
%             %% initial Vector at sensing time Building
%             if senseResult == 1 %channel sensed busy
%                 tau_chanState = [(1-obj.missedDetection )*stationProb(1,1);1-(1-obj.missedDetection )*stationProb(1,1)]; % channel state Prob vector if Busy
%                 tau = tau_chanState'*channelTransitionMat^(current_slot-senseTime); % initial vector at current time
%             elseif senseResult == 0 %sensed idle
%                 tau_chanState = [1-(1-obj.falseAlarm)*stationProb(2,1);(1-obj.falseAlarm)*stationProb(2,1)];% channel state Prob vector if idle
%                 tau = tau_chanState'*channelTransitionMat^(current_slot-senseTime); % initial vector at current time
%             else
%                 tau = stationProb;% initial vector at current time
%             end
%             tau
%             tau = [tau';zeros(2*bufferSize-2,1)]';
%             
%             %% Transition Matrix building for my scheme
%             
%             T = zeros(2*bufferSize);
%             T_D = zeros(2*bufferSize);
%             T_U = zeros(2*bufferSize);
%             
%             A_0 = [0,0; (1-pktTrProb)*obj.channelActivitySU(channelIndex,1)*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*obj.channelActivitySU(channelIndex,1)*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
%             
%             A_1 = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
%                 pktTrProb*obj.channelActivitySU(channelIndex,1)*(1-obj.falseAlarm)*channelTransitionMat(2,1)+(1-pktTrProb)*(1-obj.channelActivitySU(channelIndex,1))*channelTransitionMat(2,1)*(1-obj.falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,1)*obj.falseAlarm,pktTrProb*obj.channelActivitySU(channelIndex,1)*(1-obj.falseAlarm)*channelTransitionMat(2,2)+(1-pktTrProb)*(1-obj.channelActivitySU(channelIndex,1))*channelTransitionMat(2,2)*(1-obj.falseAlarm)+(1-pktTrProb)*channelTransitionMat(2,2)*obj.falseAlarm];
%             
%             A_2 = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
%                 pktTrProb*(1-obj.channelActivitySU(channelIndex,1))*(1-obj.falseAlarm)*channelTransitionMat(2,1)+pktTrProb*obj.falseAlarm*channelTransitionMat(2,1),pktTrProb*(1-obj.channelActivitySU(channelIndex,1))*(1-obj.falseAlarm)*channelTransitionMat(2,2)+pktTrProb*obj.falseAlarm*channelTransitionMat(2,2)];
%             
%             %% reward of trnsmission
%             A_0_D = [0,0; (1-pktTrProb)*obj.channelActivitySU(channelIndex,1)*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*obj.channelActivitySU(channelIndex,1)*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
%             A_1_D =[0,0;0,0];
%             A_2_D  =[0,0;0,0];
%             %% cost of failing to transmit
%             A_0_U =[0,0;0,0];
%             A_1_U = [(1-pktTrProb)*channelTransitionMat(1,1),(1-pktTrProb)*channelTransitionMat(1,2);
%                 (1-pktTrProb)*(1-obj.channelActivitySU(channelIndex,1))*channelTransitionMat(2,1)*(1-obj.falseAlarm),(1-pktTrProb)*(1-obj.channelActivitySU(channelIndex,1))*channelTransitionMat(2,2)*(1-obj.falseAlarm)];
%             A_2_U = [pktTrProb*channelTransitionMat(1,1),pktTrProb*channelTransitionMat(1,2);
%                 pktTrProb*(1-obj.channelActivitySU(channelIndex,1))*(1-obj.falseAlarm)*channelTransitionMat(2,1),pktTrProb*(1-obj.channelActivitySU(channelIndex,1))*(1-obj.falseAlarm)*channelTransitionMat(2,2)];
%             
%             
%             T(1:2,1:2) = A_1;
%             T(1:2,3:4) = A_2;
%             T((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0;
%             T((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1+A_2;
%             
%             T_D(1:2,1:2) = A_1_D;
%             T_D(1:2,3:4) = A_2_D;
%             T_D((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0_D;
%             T_D((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1_D+A_2_D;
%             
%             T_U(1:2,1:2) = A_1_U;
%             T_U(1:2,3:4) = A_2_U;
%             T_U((2*bufferSize-1):(2*bufferSize),(2*bufferSize-3):(2*bufferSize-2)) = A_0_U;
%             T_U((2*bufferSize-1):(2*bufferSize),(2*bufferSize-1):(2*bufferSize)) = A_1_U+A_2_U;
%             
%             
%             
%             
%             for row = 3:2:(2*bufferSize-3)
%                 T(row:row+1,(row-2):(row-1)) = A_0;
%                 T(row:row+1,row:row+1) = A_1;
%                 T(row:row+1,(row+2):(row+3)) = A_2;
%                 
%                 T_D(row:row+1,(row-2):(row-1)) = A_0_D;
%                 T_D(row:row+1,row:row+1) = A_1_D;
%                 T_D(row:row+1,(row+2):(row+3)) = A_2_D;
%                 
%                 T_U(row:row+1,(row-2):(row-1)) = A_0_U;
%                 T_U(row:row+1,row:row+1) = A_1_U;
%                 T_U(row:row+1,(row+2):(row+3)) = A_2_U;
%             end
%             
%             
%             %% absorption vector
%             T_0 = [0;(1-pktTrProb)*obj.channelActivitySU(channelIndex,1)*(channelTransitionMat(2,1)+channelTransitionMat(2,2)*(1-obj.falseAlarm));zeros(2*bufferSize-2,1)];
%             
%             
%             cumProb = 0;
%             reward = 0;
%             n = 1;
%             while  n< Q   %%cumProb <0.95 &&
%                 %prob = tau*T^n*T_0;
%                 prob = T^n*T_0;
%                 %cumProb = cumProb + prob;
%                 %reward = reward + n*prob;
%                 reward = reward + prob;
%                 n = n+1;
%                 
%             end
%             reward
%             tau*reward
%             Exp_U = 0;
%             Exp_D = 0;
%             
%             
%             tempSumOuter_D = 0;
%             
%             tempSumOuter_U = 0;
%             
%             for iteration = 1:(Q-1)
%                 
%                 
%                 tempSumInner_D = 0;
%                 tempSumInner_U = 0;
%                 for innerIteration = 1:(iteration-1)
%                     before = T^(innerIteration-1);
%                     after =  T^(iteration-innerIteration-1)*T_0;
%                     tempSumInner_D = tempSumInner_D + before*T_D*after;
%                     tempSumInner_U = tempSumInner_U + before*T_U*after;
%                 end
%                 tempSumOuter_D = tempSumOuter_D +tempSumInner_D;
%                 tempSumOuter_U =  tempSumOuter_U +tempSumInner_U;
%             end
%             tau*tempSumOuter_D
%             tau*tempSumOuter_U
%         end
 end
end