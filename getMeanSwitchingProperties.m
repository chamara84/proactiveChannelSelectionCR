clear all
clc


%%Getting the mean Dumb, smart and unused switches
%low value utilization of 0.2
interferenceMean_low = zeros(5,2);
controlSlotMean_low = zeros(5,1);
throughputMean_low = zeros(5,2);
interferenceVar_low = zeros(5,2);
controlSlotVar_low = zeros(5,1);
throughputVar_low = zeros(5,2);
%mid value of utilization of 0.4
interferenceMean_mid = zeros(5,2);
controlSlotMean_mid = zeros(5,1);
throughputMean_mid = zeros(5,2);
interferenceVar_mid = zeros(5,2);
controlSlotVar_mid = zeros(5,1);
throughputVar_mid = zeros(5,2);

%high value utilization of 0.8
interferenceMean_high = zeros(5,2);
controlSlotMean_high = zeros(5,1);
throughputMean_high = zeros(5,2);
interferenceVar_high = zeros(5,2);
controlSlotVar_high = zeros(5,1);
throughputVar_high = zeros(5,2);

%% theoretical 
numPU = 10;
numSU = 20;
%utilization= 0.8;
probAvailVec = ones(3,numPU);
probAvailVec(1,:) = probAvailVec(1,:)*0.8;
probAvailVec(2,:) = probAvailVec(2,:)*0.6;
probAvailVec(3,:) = probAvailVec(3,:)*0.2;
num_of_samples = 5;
snr_dB = 5;
snr = 10^(snr_dB/10);
meanCtrlSlotNum = zeros(3,5);
cumProb = 0;
prob = zeros(3,100000);

for misDetProb = 1:5
    falarmProb = solveFalseAlarm(num_of_samples, misDetProb*0.1, snr);
    for utilLevel = 1:3
        tau = 1;
        cumProb = 0;
    while cumProb < 0.95
        prob = numControlSlotsProb(numSU,probAvailVec(utilLevel,:),falarmProb,tau,numPU);
        meanCtrlSlotNum(utilLevel,misDetProb) = meanCtrlSlotNum(utilLevel,misDetProb)+tau*prob;
        cumProb = cumProb+prob;
        
        %prob(utilLevel,tau) = numControlSlotsProb(numSU,probAvail,falarmProb,tau,numPU);
        tau = tau+1;
    end
    end
end

%% Simulation
for missedDet = 1:5
low = load(strcat('C:\Users\Chamara\Documents\Transactions\MatlabCode\Results\MAP0.',num2str(missedDet),'pm_Utilization0_2.mat'));
mid = load(strcat('C:\Users\Chamara\Documents\Transactions\MatlabCode\Results\MAP0.',num2str(missedDet),'pm_Utilization0_4.mat'));
high = load(strcat('C:\Users\Chamara\Documents\Transactions\MatlabCode\Results\MAP0.',num2str(missedDet),'pm_Utilization0_8.mat'));


% for algorithm= 1:4
%     for channel = 1:10
%         dumbSwitchVec(algorithm,channel) = SBSAll(1,algorithm).PUChannelArray(1,channel).dumbSwitch;
%         smartSwitchVec(algorithm,channel) = SBSAll(1,algorithm).PUChannelArray(1,channel).smartswitch;
%         unusedSwitchVec(algorithm,channel) = SBSAll(1,algorithm).PUChannelArray(1,channel).unused;
%     end
%end

for algorithm= 1:2   
    
 %low
interferenceMean_low(missedDet,algorithm) = mean(low.interferenceVec(:,algorithm));
throughputMean_low(missedDet,algorithm) = mean(low.throughPutVec(:,algorithm));

interferenceVar_low(missedDet,algorithm) = std(low.interferenceVec(:,algorithm))/10;

throughputVar_low(missedDet,algorithm) = std(low.throughPutVec(:,algorithm))/10;
  
 %mid
interferenceMean_mid(missedDet,algorithm) = mean(mid.interferenceVec(:,algorithm));
throughputMean_mid(missedDet,algorithm) = mean(mid.throughPutVec(:,algorithm));

interferenceVar_mid(missedDet,algorithm) = std(mid.interferenceVec(:,algorithm))/10;

throughputVar_mid(missedDet,algorithm) = std(mid.throughPutVec(:,algorithm))/10;

%high
interferenceMean_high(missedDet,algorithm) = mean(high.interferenceVec(:,algorithm));
throughputMean_high(missedDet,algorithm) = mean(high.throughPutVec(:,algorithm));

interferenceVar_high(missedDet,algorithm) = std(high.interferenceVec(:,algorithm))/10;

throughputVar_high(missedDet,algorithm) = std(high.throughPutVec(:,algorithm))/10;


end
%low
controlSlotMean_low(missedDet,1) = mean(reshape(low.controlSlotsVec,20,1));
controlSlotVar_low(missedDet,1) = std(reshape(low.controlSlotsVec,20,1))/20;
%mid
controlSlotMean_mid(missedDet,1) = mean(reshape(mid.controlSlotsVec,20,1));
controlSlotVar_mid(missedDet,1) = std(reshape(mid.controlSlotsVec,20,1))/20;
%high
controlSlotMean_high(missedDet,1) = mean(reshape(high.controlSlotsVec,20,1));
controlSlotVar_high(missedDet,1) = std(reshape(high.controlSlotsVec,20,1))/20;
end

missedDet = 0.1:0.1:0.5;
figure(1)
plot1 = errorbar(missedDet,interferenceMean_low(:,1),interferenceVar_low(:,1),'-.vm');
hold on
plot2 = errorbar(missedDet,interferenceMean_low(:,2),interferenceVar_low(:,2),'-sc');
plot3 = errorbar(missedDet,interferenceMean_mid(:,1),interferenceVar_mid(:,1),'-x');
plot4 = errorbar(missedDet,interferenceMean_mid(:,2),interferenceVar_mid(:,2),'-.or');
plot5 = errorbar(missedDet,interferenceMean_high(:,1),interferenceVar_high(:,1),'-^k');
plot6 = errorbar(missedDet,interferenceMean_high(:,2),interferenceVar_high(:,2),':*g');
legend([plot1,plot2,plot3,plot4,plot5,plot6],'PST-0.2Utilization','HMM-0.2Utilization','PST-0.4Utilization','HMM-0.4Utilization','PST-0.8Utilization','HMM-0.8Utilization');
%legend([plot1,plot2],'PST-0.4Utilization','HMM-0.4Utilization');
title('Probability of Interference  Vs. Probability of Missed Detection ');
xlabel(' Probability of Missed Detection');
ylabel('Probability of Interference');
hold off

figure(2)
plot2 = errorbar(missedDet,controlSlotMean_mid(:,1),controlSlotVar_mid(:,1),'-x');
hold on
plot1 = errorbar(missedDet,controlSlotMean_low(:,1),controlSlotVar_low(:,1),'-.sm');
plot3 = errorbar(missedDet,controlSlotMean_high(:,1),interferenceVar_high(:,1),':^k');

legend([plot1,plot2,plot3],'0.2 Utiliation','0.4 Utiliation','0.8 Utiliation');
title('Number of control slots  Vs. Probability of Missed Detection ');
xlabel(' Probability of Missed Detection');
ylabel('Mean number of control slots for rendezvous');
hold off

figure(3)
plot1 = errorbar(missedDet,throughputMean_low(:,1),throughputVar_low(:,1),'-.vm');
hold on
plot2 = errorbar(missedDet,throughputMean_low(:,2),throughputVar_low(:,2),'-sc');
plot3 = errorbar(missedDet,throughputMean_mid(:,1),throughputVar_mid(:,1),'-x');
plot4 = errorbar(missedDet,throughputMean_mid(:,2),throughputVar_mid(:,2),'-.or');
plot5 = errorbar(missedDet,throughputMean_high(:,1),throughputVar_high(:,1),'-^k');
plot6 = errorbar(missedDet,throughputMean_high(:,2),throughputVar_high(:,2),':*g');
legend([plot1,plot2,plot3,plot4,plot5,plot6],'PST-0.2Utilization','HMM-0.2Utilization','PST-0.4Utilization','HMM-0.4Utilization','PST-0.8Utilization','HMM-0.8Utilization');
%legend([plot1,plot2],'PST','HMM');
title('Prabability of successful transmission per SU Vs. Probability of Missed Detection ');
xlabel('Missed Detection probability');
ylabel('Probability if Successful transmission');
hold off

figure(4)
plot4 = plot(missedDet,meanCtrlSlotNum(1,:),'-.vm');
hold on
plot5 = plot(missedDet,meanCtrlSlotNum(2,:),'-x');
plot6 = plot(missedDet,meanCtrlSlotNum(3,:),':*g');
legend([plot4,plot5,plot6],'0.2 Utilization Theoretical','0.4 Utilization Theoretical','0.8 Utilization Theoretical');
title('Theoretical upper bound for control slots  Vs. Probability of Missed Detection ');
xlabel(' Probability of Missed Detection');
ylabel('Theoretical Mean number of control slots for rendezvous');
hold off

