function makePlot(X,FILT,names,clr)
%makePlot(X, FILT, names, color)
%X: column vector of data, with each column a condition to be averaged into a bar plot
%FILT: column vector of same size as X, with 1=included and 0=excluded; filter applied column by column
%lengths must match but filters can sum to different values per column
%filter is POSITIVE ie 1= include, 0=exclude
%names is a cell array

[n,numCond] =size(X);


if(strcmp(clr,'yellow'))
    clr = [249,217,10]/255;
else
    clr= [132,132,215]/255;
end


%create vector of SEs for each of the columns in X
SE = [];
xMEAN = [];
for c=1:numCond
    
    curX = X(:,c);
    curFilt = FILT(:,c) & ~isnan(curX);
    curN=sum(curFilt);
    filtX = curX(curFilt);
    SE(c) = std(filtX/sqrt(curN-1));
    xMEAN(c) = mean(filtX);
    
end


%plot this
F1 = figure('Color','White');
errorbar_groups(xMEAN,SE,'bar_names',...
    names,'bar_colors',[clr],'FigID',F1);
set(gca,'Color',[0.8 0.8 0.8]);
set(gca,'FontSize',20);
axis([0,numCond+1,min(min(X)),max(max(X))]) 