function [ebsd,filter] = smooth(ebsd,varargin)
% smooth spatial EBSD data
%
% Input
%  ebsd - @EBSD
%
% Example
%   mtexdata forsterite
%   ebsd = ebsd('indexed');
%   % segment grains
%   [grains,ebsd.grainId] = calcGrains(ebsd)
%
%   % find largest grains
%   largeGrains = grains(grains.grainSize>800)
%   ebsd = ebsd(largeGrains(1))
%
%   figure
%   plot(largeGrains(1).boundary,'linewidth',2)
%   hold on
%   oM = ipdfHSVOrientationMapping(ebsd);
%   oM.inversePoleFigureDirection = mean(ebsd.orientations) * oM.whiteCenter;
%   oM.maxAngle = 1.5*degree;
%   plot(ebsd,oM.orientation2color(ebsd.orientations))
%   hold off
%
%   ebsd_smoothed = smooth(ebsd.gridify)
%   plot(ebsd_smoothed('indexed'),oM.orientation2color(ebsd_smoothed('indexed').orientations))
%   hold on
%   plot(largeGrains(1).boundary,'linewidth',2)
%   hold off

% read input
filter = getClass(varargin,'EBSDFilter',splineFilter);

% if possible smooth each grain seperately 
% otherwise each phase seperately
try
  grainId = ebsd.grainId;
catch
  grainId = ebsd.phaseId;
end

% extract some locale variables
CSList = ebsd.CSList;
rot = ebsd.rotations;

[grainIds,pos] = unique(grainId(:));
pos = pos(~isnan(grainIds));
grainIds = grainIds(~isnan(grainIds));
phaseIds = ebsd.phaseId(pos).';
grainIds = grainIds.';
progress(0,length(grainIds));

% find the largest grain
[~,m] = max(histc(grainId(:),0.5:1:max(grainId)+0.5));

% and sort it first
if m>1
  phaseIds = [phaseIds(grainIds==m),phaseIds(grainIds~=m)];
  grainIds = [m,grainIds(grainIds~=m)];
end

% loop through all grains or phases
for id = 1:length(grainIds)

  progress(id,length(grainIds));
  
  % the values to be smoothed
  ind = grainId == grainIds(id); 

  % maybe there is nothing to do
  if ~any(ind(:)), continue; end

  % local coordinates in a local rectangular grid
  [irow,icol] = find(ind);
  minCol = min(icol); nCol = 1 + max(icol) - minCol;
  minRow = min(irow); nRow = 1 + max(irow) - minRow;
  indLocal = sub2ind([nRow,nCol],irow - minRow + 1,icol - minCol + 1);
    
  % skip small grains
  if nnz(ind)<5 || nRow < 2 || nCol < 2 || all(isnan(rot.a(ind)))
    continue, 
  end
    
  % generate orientation grid
  ori = orientation.nan(nRow,nCol,CSList{phaseIds(id)});
  ori(indLocal) = rot(ind);
    
  % perform smoothing
  ori = filter.smooth(ori);
      
  % store as rotations
  rot(ind) = ori(indLocal);
    
end

% store to EBSD variable
ebsd.rotations = rot;
    
end
