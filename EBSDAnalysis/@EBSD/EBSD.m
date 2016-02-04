classdef EBSD < phaseList & dynProp & dynOption
  % constructor
  %
  % *EBSD* is the low level constructor for an *EBSD* object representing EBSD
  % data. For importing real world data you might want to use the predefined
  % <ImportEBSDData.html EBSD interfaces>. You can also simulate EBSD data
  % from an ODF by the command <ODF.calcEBSD.html calcEBSD>.
  %
  % Syntax
  %   ebsd = EBSD(rotations,phases,CSList)
  %
  % Input
  %  orientations - @orientation
  %  CS           - crystal / specimen @symmetry
  %
  % Options
  %  phase    - specifing the phase of the EBSD object
  %  options  - struct with fields holding properties for each orientation
  %  xy       - spatial coordinates n x 2, where n is the number of input orientations
  %  unitCell - for internal use
  %
  % See also
  % ODF/calcEBSD EBSD/calcODF loadEBSD
  
  % properties with as many rows as data
  properties
    id = []               % unique id's starting with 1    
    rotations = rotation  % rotations without crystal symmetry
    A_D = []              % adjecency matrix of the measurement points
  end
  
  % general properties
  properties
    scanUnit = 'um'       % unit of the x,y coordinates
    unitCell = []         % cell associated to a measurement
  end
  
  properties (Dependent = true)
    orientations    % rotation including symmetry
    weights         %
    grainId         % id of the grain to which the EBSD measurement belongs to
    mis2mean        % misorientation to the mean orientation of the corresponding grain
    dx              % step size in x
    dy              % step size in y
    gradientX       % orientation gradient in x
    gradientY       % orientation gradient in y
  end
  
  methods
    
    function ebsd = EBSD(rot,phases,CSList,varargin)
      %
      % Syntax 
      %   EBSD(rot,phases,CSList)
      
      if nargin == 0, return; end            
      
      ebsd.rotations = rotation(rot);
      ebsd = ebsd.init(phases,CSList);      
      ebsd.id = (1:numel(phases)).';
            
      % extract additional properties
      ebsd.prop = get_option(varargin,'options',struct);
                  
      % get unit cell
      if check_option(varargin,'uniCell')
        ebsd.unitCell = get_option(varargin,'unitCell',[]);
      else
        ebsd.unitCell = calcUnitCell([ebsd.prop.x(:),ebsd.prop.y(:)]);
      end
      
      % remove ignore phases
      if check_option(varargin,'ignorePhase')
        
        del = ismember(ebsd.phaseMap(ebsd.phaseId),get_option(varargin,'ignorePhase',[]));
        ebsd = subSet(ebsd,~del);
        
      end
            
    end
    
    % --------------------------------------------------------------

    function ori = get.mis2mean(ebsd)      
      ori = ebsd.prop.mis2mean;
      try
        ori = orientation(ori,ebsd.CS,ebsd.CS);
      catch        
      end
    end
        
    function ebsd = set.mis2mean(ebsd,ori)
      
      if length(ori) == length(ebsd)
        ebsd.prop.mis2mean = rotation(ori(:));
      elseif length(ori) == nnz(ebsd.isIndexed)
        ebsd.prop.mis2mean = idRotation(length(ebsd),1);
        ebsd.prop.mis2mean(ebsd.isIndexed) = rotation(ori);
      elseif length(ori) == 1
        ebsd.prop.mis2mean = rotation(ori) .* idRotation(length(ebsd),1);
      else
        error('The list of mis2mean has to have the same size as the list of ebsd data.')
      end
      
    end
    
    function grainId = get.grainId(ebsd)
      try
        grainId = ebsd.prop.grainId;
      catch
        error('No grainId stored in the EBSD variable. \n%s\n\n%s\n',...
          'Use the following command to store the grainId within the EBSD data',...
          '[grains,ebsd.grainId] = calcGrains(ebsd)')
      end
    end
    
    function ebsd = set.grainId(ebsd,grainId)
      if numel(grainId) == length(ebsd)
        ebsd.prop.grainId = grainId(:);
      elseif numel(grainId) == nnz(ebsd.isIndexed)
        ebsd.prop.grainId = zeros(length(ebsd),1);
        ebsd.prop.grainId(ebsd.isIndexed) = grainId;
      elseif numel(grainId) == 1
        ebsd.prop.grainId = grainId * ones(length(ebsd),1);
      else
        error('The list of grainId has to have the same size as the list of ebsd data.')
      end
    end
      
    function ori = get.orientations(ebsd)
      ori = orientation(ebsd.rotations,ebsd.CS);
    end
    
    function ebsd = set.orientations(ebsd,ori)
      
      ebsd.rotations = rotation(ori);
      ebsd.CS = ori.CS;
            
    end
           
    function w = get.weights(ebsd)
      if ebsd.isProp('weights')
        w = ebsd.prop.weights;
      else
        w = ones(size(ebsd));
      end      
    end
    
    function ebsd = set.weights(ebsd,weights)
      ebsd.prop.weights = weights;
    end
    
    function dx = get.dx(ebsd)
      uc = ebsd.unitCell;
      if size(uc,1) == 4
        dx = max(uc(:,1)) - min(uc(:,1));
      elseif size(uc,1) == 6
        dx = max(uc(:,1)) - min(uc(:,1));
      else
        dx = inf;
      end
    end
    
    function dy = get.dy(ebsd)
      uc = ebsd.unitCell;
      if size(uc,1) == 4
        dy = max(uc(:,2)) - min(uc(:,2));
      elseif size(uc,1) == 6
        dy = max(uc(:,2)) - min(uc(:,2));
      else
        dy = inf;
      end
    end
    
    function gX = get.gradientX(ebsd)
      ori = ebsd.orientations;
      if min(size(ori)) <= 1
        error('Gradient determination requires a regular grid')
      end
      
      ori_ref = ori([2:end end-1],:);
      gX = log(ori,ori_ref) ./ dx;
      gX(end,:) = - gX(end,:);
    end
    
    function gx = get.gradientY(ebsd)
    end
    
  end
      
end
