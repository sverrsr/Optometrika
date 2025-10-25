function x = surface_lens( y, z, args, flag )
% To trace through a general lens profile one needs to create a function,
% which takes two arguments ( y, z ) defining a position in the lens
% plane, an arbitrary number of additional arguments provided in the cell 
% array args, and, finally, a flag argument. On flag == 0 the function 
% should return the lens height x for the given position ( y, z ). Otherwise,
% the function should return the lens normal at this position. By convention, 
% the normal should point along the x-axis, i.e. in the same general 
% direction as the traced ray.
%
% LENS SURFACE defines a surface profile.
% the first two input arguments are coordinates in the lens plane, the
% third argument is a cell array holding the lens height argv{1}, the
% surface slopes argv{2:3}, and optionally the center of the data grid
% argv{4} (used to align the interpolated surface with the optical axis).

F   = args{1};   % height Z(x,y)
Fdx = args{2};   % dZ/dx, called as Fdx(y,x)
Fdy = args{3};   % dZ/dy, called as Fdy(y,x)

if numel(args) >= 4 && ~isempty(args{4})
    grid_center = args{4};
    grid_center = double(grid_center(:).');
    if numel(grid_center) < 2
        grid_center(2) = 0;
    elseif numel(grid_center) > 2
        grid_center = grid_center(1:2);
    end
else
    grid_center = [0, 0];
end

% Map lens (y_in,z_in) -> original (x_orig,y_orig)
x_orig = y + grid_center(1);      % original x
y_orig = z + grid_center(2);      % original y


if flag == 0
    % --- Return sag along x (lens axis): x = Z(x_orig, y_orig)
    x = F(x_orig, y_orig);   % <-- your F expects (x,y)

else
    % --- Return unit normal [nx, ny, nz] in lens coordinates
    % Slopes of Z at (x_orig, y_orig).
    % NOTE: Fdx/Fdy are built with {ya, xa}, so call them as (y,x):
    Zx = Fdx(y_orig, x_orig);
    Zy = Fdy(y_orig, x_orig);

    c  = 1 ./ sqrt(1 + Zx.^2 + Zy.^2);  % normalization factor

    nx = c;                 % = n_z,orig
    ny = -Zx .* c;          % = n_x,orig
    nz = -Zy .* c;          % = n_y,orig

    x = [nx, ny, nz];

    % Keep orientation (pointing ~ +x). Flip if needed:
    flipmask = (nx < 0);
    if any(flipmask, 'all')
        x(flipmask,:) = -x(flipmask,:);
    end
end

