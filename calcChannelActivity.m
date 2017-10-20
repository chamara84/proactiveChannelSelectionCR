function channelActivitySU = calcChannelActivity(matrixOfChannelAcquicision,numSU,probPktTx)
A = zeros(size(matrixOfChannelAcquicision,1),1); % number of acquired instances of the channel
U = zeros(size(matrixOfChannelAcquicision,1),1); % number of instances channel was not acquired
epsilon = zeros(size(matrixOfChannelAcquicision,1),1); % probability of channel acquired
for channelNum = 1:size(matrixOfChannelAcquicision,1) % 
    %1 for not acquired, 0 for acquired, 3 for unsensed
    A(channelNum,1) = size(find(matrixOfChannelAcquicision(channelNum,:) == 0),2);
    U(channelNum,1) = size(find(matrixOfChannelAcquicision(channelNum,:) == 1),2);
    
    if A(channelNum,1)~= 0  &&  U(channelNum,1)~= 0
        epsilon(channelNum,1) = A(channelNum,1)/(A(channelNum,1)+U(channelNum,1));
    else
        epsilon(channelNum,1) = min((numSU*probPktTx/size(matrixOfChannelAcquicision,1)),1);
    end
        
end

for channelNum = 1:size(matrixOfChannelAcquicision,1) 
    channelActivitySU = epsilon(channelNum,1)/sum(epsilon(:,1));

end



end