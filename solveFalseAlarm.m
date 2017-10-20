function epsilon = solveFalseAlarm(num_of_samples, delta, snr)
% File: solveFalseAlarm.m
% Author: Sarah Chen 
% Nov. 2007
% Function: calculate the false alarm rate for a given miss detection rate
% snr = sigma_1^2 / sigma_0^2 - 1;
% delta = gammainc(threshold,N/2);
% epsilon = 1 - gammainc(threshold *(snr+1),N/2);

if(delta == 1)
    epsilon = 0;
elseif(delta == 0)
    epsilon = 1;
else
    threshold = real(fsolve(@detectionThreshold,5,optimset('fsolve'),num_of_samples,delta,snr));
    epsilon = 1 - gammainc(threshold * (snr+1), num_of_samples/2);
end