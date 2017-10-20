classdef CSMAAccessSU < handle
 properties (Access = public)
     puChannelStates %a binary string containing PU channel usage at each slot
     channelAgainstSUBackoff % a matrix containing backoff durations of each SU against channel ,100 indicating SU not using channel
     numChannelsSUAccessPerSlot % the number of channels an SU access in a slot
     numChannels % the number of total channels
     numSU %number of secondary users
     suObjectVector % a vector containing SU objects
     slotNumber % the simulated PU slot number
     subSlotNumber % the subslot number
     allocChannels %allocated channels in each main slot
     channelAccessProbSU % channel access probabilty of an SU
     bufferSize %size of SU buffer
     CW %contention window
     t_rts %length of RTS in time
     vulnerTime %length of the vulnerable period in time
 end
 
 properties (Access=private)
 end
 
 methods
     function obj = CSMAAccessSU(puChannelStates,numChannels,numSU,numChannelsSUAccessPerSlot,suObjectVector,channelAccessProbSU)
         obj.puChannelStates =  puChannelStates;
         obj.numChannelsSUAccessPerSlot =numChannelsSUAccessPerSlot;
         obj.numChannels =numChannels;
         obj.numSU = numSU;
         obj.channelAgainstSUBackoff = ones(numChannels,numSU)*(3);
         obj.suObjectVector =  suObjectVector;
         obj.slotNumber = 1;
         obj.subSlotNumber = 1;
         obj.allocChannels  = zeros(obj.numChannels,2);
         obj.channelAccessProbSU = channelAccessProbSU;
         obj.bufferSize = 10;
         obj.CW = 29;
         obj.t_rts = 16e-3 + 4e-3+ ((16+6)+(20+obj.numChannelsSUAccessPerSlot)*8)/1000; %each channel index take one byte
         obj.vulnerTime = obj.t_rts + 5e-3; %5us is the propagation time
     end
      
     function allocChannelToSU(obj,algorithm)
         
         for i=1:obj.numSU
            
             if obj.suObjectVector(1,i).isHandshakeDone == 0 && obj.suObjectVector(1,i).isTransmiting == 1 && obj.subSlotNumber == 1
                 
                 if obj.suObjectVector(1,i).senseOne(obj.puChannelStates,mod(obj.slotNumber,obj.numChannels)+1,obj.slotNumber)== '0'
                      obj.channelAgainstSUBackoff(mod(obj.slotNumber,obj.numChannels)+1,i) = randi(obj.CW)*9e-3;
                      obj.suObjectVector(1,i).channelAccessMemory(mod(obj.slotNumber,obj.numChannels)+1,1) = obj.suObjectVector(1,i).channelAccessMemory(mod(obj.slotNumber,obj.numChannels)+1,1)+1;
                      
                 elseif obj.suObjectVector(1,i).senseOne(obj.puChannelStates,mod(obj.slotNumber,obj.numChannels)+1,obj.slotNumber)== '1'
                      obj.channelAgainstSUBackoff(mod(obj.slotNumber,obj.numChannels)+1,i) = 100; 
                     
                 end
             elseif obj.suObjectVector(1,i).isHandshakeDone == 1 && obj.suObjectVector(1,i).isTransmiting == 1 && obj.subSlotNumber == 1
                      obj.suObjectVector(1,i).predict(algorithm,obj.bufferSize,obj.slotNumber);
                      obj.suObjectVector(1,i).sense(obj.puChannelStates,obj.slotNumber);
                       if obj.suObjectVector(1,i).senseOne(obj.puChannelStates,obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),obj.slotNumber)== '0'
                            obj.channelAgainstSUBackoff(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),i) = randi(obj.CW)*9e-3;
                            obj.suObjectVector(1,i).channelAccessMemory(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),1) = obj.suObjectVector(1,i).channelAccessMemory(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),1)+1;
                       elseif obj.suObjectVector(1,i).senseOne(obj.puChannelStates,obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),obj.slotNumber)== '1'
                            obj.channelAgainstSUBackoff(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),i) = 100; 
                            
                       end
             elseif obj.suObjectVector(1,i).isHandshakeDone == 1 && obj.suObjectVector(1,i).isTransmiting == 1 && obj.subSlotNumber > 1 && obj.suObjectVector(1,i).channelAcquired == 0
                    obj.suObjectVector(1,i).predict(algorithm,obj.bufferSize,obj.slotNumber);
                     if obj.suObjectVector(1,i).senseOne(obj.puChannelStates,obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),obj.slotNumber)== '0'
                         
                         if  obj.allocChannels(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),1) == 0
                            obj.channelAgainstSUBackoff(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),i) =randi(obj.CW)*9e-3;
                            obj.suObjectVector(1,i).channelAccessMemory(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),1) = obj.suObjectVector(1,i).channelAccessMemory(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),1)+1;
                         else
                             obj.channelAgainstSUBackoff(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),i) = 100;
                             
                         end
                     elseif obj.suObjectVector(1,i).senseOne(obj.puChannelStates,obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),obj.slotNumber)== '1'
                            obj.channelAgainstSUBackoff(obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1),i) = 100; 
                            
                     end
             elseif obj.suObjectVector(1,i).isHandshakeDone == 1 && obj.suObjectVector(1,i).isTransmiting == 1 && obj.subSlotNumber > 1 && obj.suObjectVector(1,i).channelAcquired == 1
                     
                 obj.suObjectVector(1,i).channelAccessMemory(find(obj.allocChannels(:,1)==i),1) = obj.suObjectVector(1,i).channelAccessMemory(find(obj.allocChannels(:,1)==i),1)+1;              
                 
             end
             
                 
         end
         
         [valuebackoff, index_backOff] = sort(obj.channelAgainstSUBackoff,2);
         
         
         
       
         for channelIndex = 1:obj.numChannels
             
            if valuebackoff(channelIndex,1) < 1 && (valuebackoff(channelIndex,2)-valuebackoff(channelIndex,1)) > obj.vulnerTime
               
                if obj.allocChannels(channelIndex,1) == 0 || obj.allocChannels(channelIndex,1) == -1
                    obj.allocChannels(channelIndex,1) = index_backOff(channelIndex,1); 
                    obj.allocChannels(channelIndex,2) = obj.numChannelsSUAccessPerSlot - obj.subSlotNumber +1;
                    
                elseif obj.allocChannels(channelIndex,1) > 0 && obj.suObjectVector(1,index_backOff(channelIndex,1)).isTransmiting == 0 
                    obj.allocChannels(channelIndex,1) = index_backOff(channelIndex,1); 
                    obj.allocChannels(channelIndex,2) = obj.numChannelsSUAccessPerSlot - obj.subSlotNumber +1;
                end
                
            
            elseif valuebackoff(channelIndex,1) < 1 && (valuebackoff(channelIndex,2)-valuebackoff(channelIndex,1)) <= obj.vulnerTime    
                if obj.allocChannels(channelIndex,1) == 0 || obj.allocChannels(channelIndex,1) == -1
                    obj.allocChannels(channelIndex,1) = -1; 
                    obj.allocChannels(channelIndex,2) = obj.numChannelsSUAccessPerSlot - obj.subSlotNumber +1;
                    
                elseif obj.allocChannels(channelIndex,1) > 0 && obj.suObjectVector(1,index_backOff(channelIndex,1)).isTransmiting == 0 
                    obj.allocChannels(channelIndex,1) = -1; 
                    obj.allocChannels(channelIndex,2) = obj.numChannelsSUAccessPerSlot - obj.subSlotNumber +1;
                end
                
                
            else
                
                obj.allocChannels(channelIndex,:) = [0,0];
            end
         end
%          
%          for i=1:obj.numSU
%              if size(obj.suObjectVector(1,i).channelAccessMemory,2)>=1000
%                  obj.suObjectVector(1,i).channelAccessMemory(:,1) = [];
%              end
%              if isempty(obj.suObjectVector(1,i).channelSwitchOrder)~=1
%                  SUMemLen = size(obj.suObjectVector(1,i).channelAccessMemory,2);
%              end
%              
%              for channelIndex = 1:obj.numChannels
%                  if isempty(obj.suObjectVector(1,i).channelSwitchOrder)~=1 && obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1)== channelIndex && obj.suObjectVector(1,i).isTransmiting == 1
%                      if obj.allocChannels(channelIndex,1)== i
%                          obj.suObjectVector(1,i).channelAccessMemory(channelIndex,SUMemLen+1) = 0;
%                      else
%                          obj.suObjectVector(1,i).channelAccessMemory(channelIndex,SUMemLen+1) = 1;
%                      end
%                  elseif isempty(obj.suObjectVector(1,i).channelSwitchOrder)~=1 && (obj.suObjectVector(1,i).channelSwitchOrder(obj.subSlotNumber,1)~= channelIndex || obj.suObjectVector(1,i).isTransmiting ~= 1)
%                      obj.suObjectVector(1,i).channelAccessMemory(channelIndex,SUMemLen+1) = 3;
%                  end
%                  
%              end
%          end
         
%           disp('Channel Allocation');
%           disp(obj.allocChannels);
%          disp('Values');
%          disp(valuebackoff(:,1));
         
    %% modify here onwards and catch the -1 for collided time slots
         for channelIndex = 1:obj.numChannels
            if  obj.puChannelStates(channelIndex,1) == '1' && obj.allocChannels(channelIndex,1)> 0
               
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired = 0;
%                 disp('SU index = ');
%                 disp(obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).SUIndex);
%                 disp('channel Acquired out = ');
%                 disp(channelIndex);
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).acquireChannel(channelIndex,obj.numChannelsSUAccessPerSlot,obj.numChannels,obj.numSU,obj.channelAccessProbSU,obj.bufferSize,obj.slotNumber,algorithm);   
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).cumulativeInterferedSlots = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).cumulativeInterferedSlots +1;
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2) = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2)+1;
                
                
            elseif obj.puChannelStates(channelIndex,1) == '0' && obj.allocChannels(channelIndex,1)> 0
                
                
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).acquireChannel(channelIndex,obj.numChannelsSUAccessPerSlot,obj.numChannels,obj.numSU,obj.channelAccessProbSU,obj.bufferSize,obj.slotNumber,algorithm);
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).transmit(obj.allocChannels(channelIndex,2));
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2) = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2)+1;
                
                if obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).isHandshakeDone == 0 && obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).isTransmiting == 1
                    obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).isHandshakeDone = 1;
                    obj.suObjectVector(1,i).sense(obj.puChannelStates,obj.slotNumber);
                    obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired = 1;
                    
                end
                if obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired == 0 && obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).isTransmiting == 1
                    obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired = 1;
                    
                end
                
        %% handeling collisions        
            elseif  obj.puChannelStates(channelIndex,1) == '1' && obj.allocChannels(channelIndex,1) == -1
               
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired = 0;
%                 disp('SU index = ');
%                 disp(obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).SUIndex);
%                 disp('channel Acquired out = ');
%                 disp(channelIndex);
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).acquireChannel(channelIndex,obj.numChannelsSUAccessPerSlot,obj.numChannels,obj.numSU,obj.channelAccessProbSU,obj.bufferSize,obj.slotNumber,algorithm);   
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).cumulativeInterferedSlots = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).cumulativeInterferedSlots +1;
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2) = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2)+1;
                collidedSUs = index_backOff(channelIndex,find(valuebackoff(channelIndex,:)<=valuebackoff(channelIndex,1)+obj.vulnerTime ));
                obj.suObjectVector(1,collidedSUs).cumulativeCollisionSlots = obj.suObjectVector(1,collidedSUs).cumulativeCollisionSlots +1;
           
            
            elseif  obj.puChannelStates(channelIndex,1) == '0' && obj.allocChannels(channelIndex,1) == -1
               
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAcquired = 0;
%                 disp('SU index = ');
%                 disp(obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).SUIndex);
%                 disp('channel Acquired out = ');
%                 disp(channelIndex);
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).acquireChannel(channelIndex,obj.numChannelsSUAccessPerSlot,obj.numChannels,obj.numSU,obj.channelAccessProbSU,obj.bufferSize,obj.slotNumber,algorithm);   
                obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2) = obj.suObjectVector(1,obj.allocChannels(channelIndex,1)).channelAccessMemory(channelIndex,2)+1;
                collidedSUs = index_backOff(channelIndex,find(valuebackoff(channelIndex,:)<=valuebackoff(channelIndex,1)+obj.vulnerTime ));
                obj.suObjectVector(1,collidedSUs).cumulativeCollisionSlots = obj.suObjectVector(1,collidedSUs).cumulativeCollisionSlots +1;
            end
                
         end
         
     end
     
     
 end

end