function sequence = MAP_rv_gen_mul(num_slots,s4,D1)

%[s1,s2,s3,s4,s5,s6] = RandStream.create('mrg32k3a','NumStreams',6);
phase = ones(3,1);

pi1 = zeros(size(D1,2),1);
pi1(1,1) =1;
      
  
%%  channel one distribution  
    
r = rand(s4,1);

for row=1:size(D1,1)                                 % getting the starting phase
    
    if row==1 && r<=pi1(row)
        phase(1) = 1;
        
    elseif row > 1
        if  r > sum(pi1(1:row-1,1)) && r <= sum(pi1(1:row,1))
            phase(1) = row;
        end
    end
end

%%
sequence = zeros(1,num_slots);  % sequence containing the on and off times 48 for off and 49  for on


%% sequence for the channel 1

for slots= 1:num_slots
    r = rand(s4,1);
    
    for col=1:size(D1,2)
        
        if col==1 && r<=D1(phase(1),col)
            phase(1) = col;
            break;

        elseif col > 1
            if  r > sum(D1(phase(1),1:col-1)) && r <= sum(D1(phase(1),1:col))
                phase(1) = col;
                break;
            end
        end  
    end
    %assign idle and busy according to the phase the chain is in
    
    if phase(1) >=2 
        sequence(1,slots)= '0';
    else 
        sequence(1,slots)= '1';
    end
%     phases(1,slots) = phase(1);
%     r_values(1,slots) = r;
end



end