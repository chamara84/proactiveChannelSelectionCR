function y = detectionThreshold(x,num_of_samples,delta,snr)
% File: detectionThreshold.m
% Author: Sarah Chen 
% Nov. 2007
% Function: calculate the detection threshold of the energy detector for a
%           given miss detection rate
% delta = gammainc(threshold,N/2)

 y = gammainc(x, num_of_samples/2) - delta;
