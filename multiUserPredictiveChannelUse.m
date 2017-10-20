classdef multiUserPredictiveChannelUse < handle
    
    properties(Access =public)
        CSMAAccess;
        SUarray;
        InterferedSubSlots;
        length_train;
        numChannelsSUAccessPerSlot;
        commonChanUsed;
    end
    properties(Access=private)
        algorithm
        hmmModel
        probFalse
        probMissed
    end
    methods
        function obj = multiUserPredictiveChannelUse(algorithmIn,SUAccessProb)
            
            obj.algorithm = algorithmIn; %1 for PST1, 2 for PST1, 3 for HMM and 4 for MLP
            obj.probMissed = 0.1;
            obj.hmmModel = load(strcat('hmm_model_params_Q_10_subseq_',num2str(obj.probMissed),'Pm_MAP.mat'), '-mat', 'obsmat_final1','prior_final1','transmat_final1');
            obj.InterferedSubSlots = 0;
            %hmmModel = load(strcat('hmm_model_params_Q_10_negbin',num2str(probMissed),'.mat'), '-mat', 'obsmat_final1','prior_final1','transmat_final1');
            %mlpModel = load(strcat('MLP_model_params_10_14_21_1_negBin_',num2str(probMissed),'.mat'),'-mat','net','Layers');
            %% MAP distribution generation
            mean_burst_length = 10;
            utilization = [0.2*ones(1,4),0.4*ones(1,4),0.8*ones(1,2)];
            meanIdleDuration = mean_burst_length*(1-utilization)./utilization;
            number_of_states = 6 ;
            obj.length_train = 200;
            s4 = RandStream.create('mrg32k3a','NumStreams',1);
            D = cell(3,1);
            train_seq = [];
            for utilIndex = 1:3
                D{utilIndex,1} = selfSimMAP(number_of_states,mean_burst_length,utilization(1,utilIndex));
                train_seq  = [train_seq;MAP_rv_gen_mul(obj.length_train,s4,D{utilIndex,1} )];
           
            
            
            %% Erlang
%             on_rate = 2.5;
%             off_rate = 1.5;
%             delay = 0.2;
%             train_slots = 50000;
%             train_seq  = ErlangSampleGenSingleChannel( off_rate,on_rate,delay);
             
             %% Negbin
             %successes = 5;
             %utilization = 0.4;
             %burstlength = 10;
             %obj.length_train =20000;
             %train_seq = negbinSampleGen(successes,utilization, burstlength, length_train);
             
           
            
            num_of_samples = 5;
            snr_dB = 5;
            snr = 10^(snr_dB/10);
            obj.probFalse = solveFalseAlarm(num_of_samples, obj.probMissed, snr);
            
            
            for index = 1:size(train_seq,2)
                
                if train_seq(utilIndex,index) == '0'
                    if rand()<=obj.probFalse
                        train_seq(utilIndex,index) = '1';
                    end
                    
                else
                    if rand()<=obj.probMissed
                        train_seq(utilIndex,index) = '0';
                        
                    end
                end
                
            end
            end
            %% PST model
            ab = alphabet('10');
            params.ab_size = size(ab);
            params.d = 10;
            params.pMin = 0.006;
            params.alpha= 0;
            params.gamma = 0.0006;
            params.r = 1.05;
            
            %javaclasspath({'/Users/umdevana/Documents/MatlabCode/matlabVMM_2.1.2/vmm/trove.jar', ...
            %    '/Users/umdevana/Documents/MatlabCode/matlabVMM_2.1.2/vmm/
            %    vmm.jar'}); % MAC
            
             javaclasspath({'C:\Users\Chamara\Documents\Transactions\MatlabCode\matlabVMM_2.1.2\vmm\trove.jar', ...
                'C:\Users\Chamara\Documents\Transactions\MatlabCode\matlabVMM_2.1.2\vmm\vmm.jar'}); 
            pstModel = cell(3,1);
            
            for utilIndex = 1:3
                pstModel{utilIndex,1} = vmm_create(map(ab,train_seq(utilIndex,:)), 'PST', params);
            end
            
            
            
            %% Network model parameters
            numberOfPUChannels = 10;
            numberOfSUs = 20;
            obj.numChannelsSUAccessPerSlot = 3;
            %stationaryProbOfChIdle =ones(1,numberOfPUChannels);
            probChannelIdle = [0.2*ones(1,4),0.4*ones(1,4),0.8*ones(1,2)]; % for MAP
            %probChannelIdle = on_rate/(on_rate+off_rate);
            stationaryProbOfChIdle =probChannelIdle;
            channelAccessProbSU = SUAccessProb; % channel access probability of SUs
            obj.commonChanUsed = zeros(1,obj.length_train*obj.numChannelsSUAccessPerSlot);
            %% PU Channel usage
            currentSlotNo = 1;
            chanUsed = 0;
            primaryChannelVec = [];
            
            for channelNo=1:numberOfPUChannels
                
               s4= RandStream.create('mrg32k3a','NumStreams',1);
               if channelNo<=4
                   testSequence = MAP_rv_gen_mul(obj.length_train,s4,D{1,1});
               elseif channelNo>4 && channelNo<=8
                   testSequence = MAP_rv_gen_mul(obj.length_train,s4,D{2,1});
               elseif channelNo>8 && channelNo<=10
                   testSequence = MAP_rv_gen_mul(obj.length_train,s4,D{3,1});
               end
               %testSequence = negbinSampleGen(successes,utilization,burstlength,length_train); %Negbin
               primaryChannelVec = [primaryChannelVec;testSequence];
               testSequence = [];
            end
            
            %% SU object array
            obj.SUarray = [];
            ctrlSwitchOrder = (1:numberOfPUChannels)';
            for SUIndex = 1:numberOfSUs
               obj.SUarray = [obj.SUarray, SecondaryUser(SUIndex,ctrlSwitchOrder,obj.probFalse,obj.probMissed,pstModel,obj.hmmModel,meanIdleDuration,numberOfPUChannels)];
            end                                        
            
            %% CSMA Access
            disp('number of SUs');
            disp(numberOfSUs);
            obj.CSMAAccess =  CSMAAccessSU(primaryChannelVec(:,1),numberOfPUChannels,numberOfSUs,obj.numChannelsSUAccessPerSlot,obj.SUarray,channelAccessProbSU);
            
            for timeSlotNo = 1:obj.length_train
               obj.CSMAAccess.puChannelStates = primaryChannelVec(:,timeSlotNo);
               obj.CSMAAccess.slotNumber = timeSlotNo;
               obj.CSMAAccess.allocChannels = zeros(numberOfPUChannels,2);
               obj.CSMAAccess.channelAgainstSUBackoff = ones(numberOfPUChannels,numberOfSUs)*(3);
               for SUIndex = 1:numberOfSUs
                    
                    if rand()<= channelAccessProbSU
                        obj.SUarray(1,SUIndex).isTransmiting = 1;
                        obj.SUarray(1,SUIndex).numPacketsToTx = obj.SUarray(1,SUIndex).numPacketsToTx + randi(3);
%                     else
%                         obj.SUarray(1,SUIndex).isTransmiting = 0;
                    end
                end
               for SUIndex = 1:numberOfSUs
                   obj.SUarray(1,SUIndex).channelAcquired = 0;
               end
               
               for subslotNo = 1:obj.numChannelsSUAccessPerSlot
                   
                   obj.CSMAAccess.subSlotNumber = subslotNo; 
                   
                
               obj.CSMAAccess.allocChannelToSU(obj.algorithm);
               
               tempChannelUsed = zeros(1,numberOfSUs);
                for SUIndex = 1:numberOfSUs
                   if  isempty(obj.SUarray(1,SUIndex).channelSwitchOrder)~=1
                       tempChannelUsed(1,SUIndex) = obj.SUarray(1,SUIndex).channelSwitchOrder(subslotNo,1);
                   end
                end
                
                 searchedChannels(1,:) = [tempChannelUsed(1,1),size(find(tempChannelUsed==tempChannelUsed(1,1)),2)];
                for SUIndex = 2:numberOfSUs
                    if isempty(searchedChannels) ~= 1
                     if isempty(find(searchedChannels(:,1)==tempChannelUsed(1,SUIndex), 1))==1
                         searchedChannels= [searchedChannels;tempChannelUsed(1,SUIndex),size(find(tempChannelUsed==tempChannelUsed(1,SUIndex)),2)];
                     end
                    end
                   
                end
                if isempty(searchedChannels) ~= 1
                    obj.commonChanUsed(1,(timeSlotNo-1)*subslotNo+subslotNo)=mean(searchedChannels(:,2));
                     searchedChannels = [];
                end
               end
            end
        end
        
        function [averageInterference,avgTxRate,avgCtrlSlots,avgSUUsingSameChan,avgCollisions] = audit(obj,numberOfSUs)
            
            avgCtrlSlotsVec=zeros(1,numberOfSUs);
            avgTxRateVec=zeros(1,numberOfSUs);
            averageInterferenceVec=zeros(1,numberOfSUs);
            avgCollisions = zeros(1,numberOfSUs);
            
            for SUIndex = 1:numberOfSUs
%                    disp('cumulative ctrl Slots');
%                    disp(obj.SUarray(1,SUIndex).cumulativeCtrlSlots);
%                    disp('cumulative pkts');
%                    disp(obj.SUarray(1,SUIndex).cumulativePackets);
                   if obj.SUarray(1,SUIndex).currentAttemptCtrl ~= 0
                       obj.SUarray(1,SUIndex).cumulativeCtrlSlots = [obj.SUarray(1,SUIndex).cumulativeCtrlSlots,obj.SUarray(1,SUIndex).currentAttemptCtrl];
                   end
%                    if obj.SUarray(1,SUIndex).currentAttempt ~= 0 && obj.SUarray(1,SUIndex).pktsTranmitted ~= 0
%                        obj.SUarray(1,SUIndex).cumulativeTxslots = [obj.SUarray(1,SUIndex).cumulativeCtrlSlots,obj.SUarray(1,SUIndex).currentAttempt];
%                        obj.SUarray(1,SUIndex).cumulativePackets = [obj.SUarray(1,SUIndex).cumulativePackets,obj.SUarray(1,SUIndex).pktsTranmitted];
%                    end
%                    
                   
                   
                   
                   if size(obj.SUarray(1,SUIndex).cumulativeCtrlSlots,1)~=0 
                       avgCtrlSlotsVec(1,SUIndex) = mean(obj.SUarray(1,SUIndex).cumulativeCtrlSlots) ;
                   else
                        avgCtrlSlotsVec(1,SUIndex) = 0;
                   end
                   if obj.SUarray(1,SUIndex).currentAttempt~=0
                    %   avgTxRateVec(1,SUIndex) = mean(obj.SUarray(1,SUIndex).cumulativePackets./(obj.SUarray(1,SUIndex).cumulativeTxslots(2:end)+obj.SUarray(1,SUIndex).cumulativeCtrlSlots));
                    avgTxRateVec(1,SUIndex) = obj.SUarray(1,SUIndex).pktsTranmitted/(obj.SUarray(1,SUIndex).currentAttempt+sum(obj.SUarray(1,SUIndex).cumulativeCtrlSlots));
                   else
                       avgTxRateVec(1,SUIndex) = 0;
                   end
                   averageInterferenceVec(1,SUIndex) = obj.SUarray(1,SUIndex).cumulativeInterferedSlots/(obj.numChannelsSUAccessPerSlot*obj.length_train);
                   avgCollisions(1,SUIndex) = obj.SUarray(1,SUIndex).cumulativeCollisionSlots/(obj.numChannelsSUAccessPerSlot*obj.length_train);
            end
            
            averageInterference = mean(averageInterferenceVec);
            avgTxRate =mean(avgTxRateVec);
            avgCtrlSlots = mean(avgCtrlSlotsVec);
            avgSUUsingSameChan = mean(obj.commonChanUsed);
            avgCollisions = mean(avgCollisions);
        
        end
        
        
        
        
        
    end
end