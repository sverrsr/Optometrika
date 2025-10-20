function x = SelfDefinedPlane( y, z, args, flag )

% x = sinusoidal_surface( y, z, args, flag )
% To trace through a general lens profile one needs to create a function,
% which takes two arguments ( y, z ) defining a position in the lens
% plane, an arbitrary number of additional arguments provided in the cell 
% array args, and, finally, a flag argument. On flag == 0 the function 
% should return the lens height x for the given position ( y, z ). Otherwise,
% the function should return the lens normal at this position. By convention, 
% the normal should point along the x-axis, i.e. in the same general 
% direction as the traced ray.
    
% l = GeneralLens( r, D, func, glass, varargin ) - object constructor
    % INPUT:
    % r - 1x3 position vector
    % D - diameter
    % func - function name string
    % glass - 1 x 2 cell array of strings, e.g., { 'air' 'acrylic' }
    % varargin - an arbitrary number of parameters required by func.
    % OUTPUT:
%
%   When flag == 0 the function returns the surface sag (X coordinate)
%   evaluated at the supplied Y and Z coordinates. Otherwise it returns a
%   matrix of surface normals pointing in the +X direction.
%
%   This surface function is used by example17 to create a reflective
%   sinusoidal free-form surface for FSGD demonstrations.
%
% Copyright: 2024 Optometrika contributors

x = args{ 1 };
y = args{ 2 };
z = args{ 3 };

disp(size(x));
disp(size(y));
disp(size(z));


if flag == 0
    x = z;
else
    [Nx,Ny,Nz] = surfnorm(z);
    % normals.x = Nx;
    % normals.y = Ny;
    % normals.z = Nz;
    x = Nx;
end
end




