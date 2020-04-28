function [labels] = getLabelsBrik(I)
%getLabels(I) where I is a head file output from loadBrick. 

remainder= I.BRICK_LABS;
labels=[];

while (any(remainder))
    [chopped,remainder] = strtok(remainder,'~');
    labels = strvcat(labels, chopped);
end



end
           