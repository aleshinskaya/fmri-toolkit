function [fR] = fisher(x)

	
	[rows,cols,z]=size(x);
	fR = zeros(rows,cols,z);

	for i=1:rows
		for j=1:cols
			for k=1:z
			f = 0.5*log((1+x(i,j,k))/(1-x(i,j,k)));
			fR(i,j,k) = f;

        end
   end
end
end
