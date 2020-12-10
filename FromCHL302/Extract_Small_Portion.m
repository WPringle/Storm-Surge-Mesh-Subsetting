function obj = Extract_Small_Portion( obj, dj_cutoff, proj, nscreen )
%  obj =  Extract_Small_Portion( obj, dj_cutoff, proj, nscreen )
%  The disconnected small portions of the msh object (containing p and t)
%  is  returned. 
%  
%  dj_cutoff indicates the size of the "small portion":
%           >= 1 : area in km2
%           < 1  : proportion of the total mesh area
%  ncscreen ~= 0  : will display info to screen
%  proj      = 0  : mesh is in geographical coordinates (needs projecting)
%            = 1  : mesh already projected (default)
%
%  Written by William Pringle based on Make_Mesh_Boundaries_Traversable.m

%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
% 
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
% 
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.  

% Checking input
if nargin < 2
    error('"dj_cutoff" input required for Extract_Small_Portion')
end
if dj_cutoff == 0
    warning('dj_cutoff is zero; do nothing')
    % do nothing
    return; 
elseif dj_cutoff < 0
    error('Keep cannot be negative 0')
end
if nargin < 3
   % already projected
   proj = 1; 
end
if nargin < 4
   % display outputs
   nscreen = 1;
end

% Get p and t out of obj
p = obj.p; t = obj.t;

if proj
    % has already been projected so get lat-lon for area computation
    [X,Y] = m_xy2ll(p(:,1),p(:,2));  
else
    % not projected so keep the lat-lon for area computation
    X = p(:,1); Y = p(:,2);  
    % project for mesh fixing check
    [p(:,1),p(:,2)] = m_ll2xy(p(:,1),p(:,2));  
    obj.p = p;
end

% fix mesh
obj = fixmeshandcarry(obj);

L = size(t,1); 
t1 = t; t = [];

% calculate area
A = sum(polyarea(X(t1)',Y(t1)').*cosd(mean(Y(t1)')));

An = A;
if dj_cutoff >= 1
    % Convert area to km2
    Re2 = 111^2; 
    An = Re2*An;
    % Absolute area
    while An > dj_cutoff

        % Peform the Breadth-First-Search to get nflag
        nflag = BFS(p,t1);

        % Get new triangulation and its area
        t2 = t1(nflag == 1,:);
        An = Re2*sum(polyarea(X(t2)',Y(t2)').*cosd(mean(Y(t2)'))); 
        
        % If small enough add t2 to the triangulation
        if An < dj_cutoff
            t = [t; t2]; 
        end
        % Delete where nflag == 1 since this patch didn't meet the fraction
        % limit criterion.
        t1(nflag == 1,:) = []; 
        % Calculate the remaining area       
        An = Re2*sum(polyarea(X(t1)',Y(t1)').*cosd(mean(Y(t1)'))); 
    end
    % If small enough add t2 to the triangulation
    if An < dj_cutoff
        t = [t; t1]; 
    end
elseif dj_cutoff > 0
    % Area proportion
    while An/A > dj_cutoff

        % Peform the Breadth-First-Search to get nflag
        nflag = BFS(p,t1);

        % Get new triangulation and its area
        t2 = t1(nflag == 1,:);
        An = sum(polyarea(X(t2)',Y(t2)').*cosd(mean(Y(t2)'))); 
        
        % If small enough add t2 to the triangulation
        if An/A < dj_cutoff
            t = [t; t2]; 
        end
        % Delete where nflag == 1 since this patch didn't meet the fraction
        % limit criterion.
        t1(nflag == 1,:) = []; 
        % Calculate the remaining area       
        An = sum(polyarea(X(t1)',Y(t1)').*cosd(mean(Y(t1)'))); 
    end
    % If small enough add t2 to the triangulation
    if An/A < dj_cutoff
        t = [t; t1]; 
    end
end

% Now delete the disjoint nodes
obj.t = t;
obj = fixmeshandcarry(obj);
[etbv,vxe] = extdom_edges2( obj.t, obj.p ) ;
if numel(etbv) > numel(vxe)
   error('boundary not traversable'); 
end
if ~proj
    % not projected so get back the lat-lon 
    % project for mesh fixing check
    p = obj.p;
    [p(:,1),p(:,2)] = m_xy2ll(p(:,1),p(:,2));  
    obj.p = p;
end


if nscreen
    disp(['  ACCEPTED: deleting ' num2str(L-size(t,1)) ...
          ' elements outside main mesh']) ;
end
if size(t,1) < 1
    error(['All elements have been deleted... something wrong? ' ...
           'dj_cutoff is set to' num2str(dj_cutoff)])
end
%EOF
end

% Subfunction Breadth-First-Search
function nflag = BFS(p,t1)

    % Select a random element.
    EToS =  randi(size(t1,1),1);

    % Get element-to-element connectivity.
    tri = triangulation(t1,p);
    nei = tri.neighbors;

    % Traverse grid deleting elements outside.
    ic = zeros(ceil(sqrt(size(t1,1))*2),1);
    ic0 = zeros(ceil(sqrt(size(t1,1))*2),1);
    nflag = zeros(size(t1,1),1);
    ic(1) = EToS;
    icc  = 1;

    % Using BFS loop over until convergence is reached (i.e., we
    % obtained a connected region).
    while icc
        ic0(1:icc) = ic(1:icc);
        icc0 = icc;
        icc = 0;
        for nn = 1:icc0
            i = ic0(nn);
            % Flag the current element as OK
            nflag(i) = 1;
            % Search neighbouring elements
            nb = nei(i,:); 
            nb(isnan(nb)) = []; 
            % Flag connected neighbors as OK
            for nnb = 1:length(nb)
                if ~nflag(nb(nnb))
                    icc = icc + 1;
                    ic(icc) = nb(nnb);
                    nflag(nb(nnb)) = 1;
                end
            end
        end
    end
end