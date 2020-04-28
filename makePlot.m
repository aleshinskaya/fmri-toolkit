function makePlot(X,FILT,names,clr)
%makePlot(X, FILT, names, color)
%X: column vector of data, with each column a condition to be averaged into a bar plot
%FILT: column vector of same size as X, with 1=included and 0=excluded; filter applied column by column
%names: cell array of condition names, corresponding to columns in X
% clr: optional 3-item vector of RGB values for the color desired for the bars
% Author: Anna Leshinskaya
% References: calls errorbar_groups by pierremegevand
% https://www.mathworks.com/matlabcentral/fileexchange/47250-pierremegevand-errorbar_groups

[n,numCond] =size(X);

% default color is yellow
if(is.empty(clr))
    clr = [249,217,10]/255;
end


%create vector of standard errors for each of the columns in X
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