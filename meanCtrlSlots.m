clear all
clc
numPU = 10;
numSU = 20;
utilization= 0.4;
probAvail = ones(1,numPU)*utilization;
num_of_samples = 5;
snr_dB = 5;
snr = 10^(snr_dB/10);
meanCtrlSlotNum = zeros(1,5);
prob = zeros(1,100);

for misDetProb = 1:5
    falarmProb = solveFalseAlarm(num_of_samples, misDetProb*0.1, snr);
    for tau = 1:20
        meanCtrlSlotNum(1,misDetProb) = meanCtrlSlotNum(1,misDetProb)+tau*numControlSlotsProb(numSU,probAvail,falarmProb,tau,numPU);
        prob(1,tau) = numControlSlotsProb(numSU,probAvail,falarmProb,tau,numPU);
    end
end
probMissDet = (1:5)*0.1;
plot(probMissDet,meanCtrlSlotNum(1,:));