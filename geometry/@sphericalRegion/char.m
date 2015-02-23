function s = char(sR)
% convert spherical region to char

switch length(length(sR.N))  
  case 0
    s = 'full sphere';
  case 1
    if sR.isUpper
      s = 'upper hemisphere';
    else
      s = 'lower hemisphere';
    end
  case 2
end

end
