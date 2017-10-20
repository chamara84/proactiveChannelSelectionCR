function D = selfSimMAP(n,burst_length,channel_utilization)

b = sym('b', 'real'); 
a = sym('a','real');
k = sym ('k','real');
j = sym ('j','real');
eqn1 = (1-1/b)/(1-1/b^n) - channel_utilization;

b_val = solve(eqn1,b);


for m= 1:size(b_val,1)
   if isreal(b_val(m,1)) == 1
       b_index = m;
       break;
   end
end

eqn2 = (symsum(1/(a^k),k, 1, n-1)) - 1/burst_length;
 a_val = solve(eqn2,a);

 
 for m= 1:size(a_val,1)
   if isreal(a_val(m,1)) == 1
       a_index = m;
       break;
   end
end
 D = zeros(n,n);
 
 for row = 1:n
    for col = 1:n
       if row == 1 && col==1
           D(row,col) = 1-double(symsum(1/((a_val(a_index,1))^j),j,1,n-1));
       elseif row ==1 && col~=1
           D(row,col) = 1/(a_val(a_index,1))^(col-1);
       elseif row~=1 && col==1
           D(row,col) = (b_val(b_index,1)/a_val(a_index,1))^(row-1);
       elseif row == col && row~=1
           D(row,col) = 1-(b_val(b_index,1)/a_val(a_index,1))^(row-1);
       end
        
    end
     
 end
 
 
end