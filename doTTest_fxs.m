function doTTest_fxs(x,y,filter,description,tails)
%doTTEST(x,y,filter,dscription, tails): must supply COLUMN VECTORS
%x will be filtered by filter
%if y is a single value, x will be compared to mean  = y
%if y is a vector, it will also be filtered by filter
% if you want different filters, just pre-filter x and y
%this functions handles nans

isPaired = length(y)>1;

if(isPaired) 
    
    %same filter applied to both column vectors
    filter = filter &  ~isnan(x) & ~isnan(y);
    [h,p,c,stats]=ttest(x(filter),y(filter),.05,tails);
    meanX= mean(x(filter)-y(filter));
    eff = mes(x(filter),y(filter),'hedgesg');
    efSize = eff.hedgesg;
    
    n = sum(filter);
    
    meanX = mean(x(filter));
    SEx = std(x(filter))/sqrt(n-1) ;
    meanY = mean(y(filter));
    SEy = std(y(filter))/sqrt(n-1);
    
    stats.sd/sqrt(n-1);
    fprintf('\n     %s: mean-x %.4f, SE -x = %.4f,  mean-y %.4f, SE-y = %.4f, CI [%.4f, %.4f], with t(%d) = %.2f, p = %.5f, d = %.2f\n',...
        description,meanX,SEx,meanY,SEy,c(1),c(2),stats.df,stats.tstat,p,efSize)

    
else   
    filter = filter & ~isnan(x);
    [h,p,c,stats]=ttest(x(filter),y,.05,tails);   
    meanX = mean(x(filter));
     eff = mes(x(filter),y,'g1');
    efSize = eff.g1;
    n = sum(filter);
    SE = stats.sd/sqrt(n-1);
    fprintf('\n     %s: mean %.4f, SE = %.4f, CI [%.4f, %.4f], with t(%d) = %.2f, p = %.5f, d = %.2f\n',description,meanX,SE,c(1),c(2),stats.df,stats.tstat,p,efSize)

end



%     curX = X(:,c);
%     curFilt = FILT(:,c) & ~isnan(curX);
%     curN=sum(curFilt);
%     filtX = curX(curFilt);

end