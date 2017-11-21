function sF = drho(sF);

fhat = zeros(size(sF.fhat));
for m = 0:sF.M
	fhat(m*(m+1)+(-m:m)+1) = i*(-m:m)'.*sF.fhat(m*(m+1)+(-m:m)+1);
end
sF = sphFunHarmonic(fhat);

end
