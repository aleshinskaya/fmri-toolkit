function [split_resp] = stringSplitAll(str)

    remain_resp = str;
    split_resp = [];
    
    count=1;  
    ind=1;
    
   while (count<=length(str))
     
        
        if(str(count) == ',')
            split_resp(ind) = NaN;
            
             %if we ended with a comma, add another NaN after it too
             if(count==length(str))
                   split_resp(ind+1) = NaN;
             end
             
        else           
               %fill in buffer
                buff='';
          
                while(count<=length(str) && str(count) ~= ',') 
                    buff(end+1) = (str(count));
                    count=count+1;
                end
                
                
                try 
                    split_resp(ind) = str2num(buff);
                catch
                    %if this wasn't a number string 
                    split_resp(ind) = NaN;
                end
                if(count==length(str))
                   split_resp(ind+1) = NaN;
                end
                
        end
        
      
       ind=ind+1;
       count=count+1;
   end
    
end


    
    
    