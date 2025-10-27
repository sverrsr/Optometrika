function x = surface_lens_corrected( y, z, args, flag )
% surface_lens_corrected  Evaluate an interpolated freeform surface.
%
%   This variant expects surface height and slope interpolants that accept
%   coordinates in the original (x,y) order. It therefore pairs with
%   examplesurface_lensRun_corrected, which builds those interpolants with
%   consistent axis ordering.
%
%   INPUTS (same convention as surface_lens):
%     y, z   - Lens-plane coordinates (mm).
%     args   - Cell array with:
%              {1} F   : sag interpolant evaluated as F(x, y).
%              {2} Fdx : ∂Z/∂x interpolant evaluated as Fdx(x, y).
%              {3} Fdy : ∂Z/∂y interpolant evaluated as Fdy(x, y).
%              {4} grid_center (optional) : [x0, y0] shift applied before
%                  evaluating the interpolants.
%              {5} x_limits (optional) : [xmin, xmax] clamp for original x.
%              {6} y_limits (optional) : [ymin, ymax] clamp for original y.
%     flag  - When 0 return sag, otherwise return the unit surface normal.

F   = args{1};   % height Z(x,y)
Fdx = args{2};   % dZ/dx
Fdy = args{3};   % dZ/dy

arg_idx = 4;
grid_center = [0, 0];
if numel(args) >= arg_idx && ~isempty(args{arg_idx})
    grid_center = double(args{arg_idx}(:).');
    if numel(grid_center) < 2
        grid_center(2) = 0;
    elseif numel(grid_center) > 2
        grid_center = grid_center(1:2);
    end
    arg_idx = arg_idx + 1;
end

x_limits = [-inf, inf];
y_limits = [-inf, inf];
if numel(args) >= arg_idx && ~isempty(args{arg_idx})
    x_limits = double(args{arg_idx}(:).');
    if numel(x_limits) < 2
        x_limits(2) = x_limits(1);
    elseif numel(x_limits) > 2
        x_limits = x_limits(1:2);
    end
    arg_idx = arg_idx + 1;
end
if numel(args) >= arg_idx && ~isempty(args{arg_idx})
    y_limits = double(args{arg_idx}(:).');
    if numel(y_limits) < 2
        y_limits(2) = y_limits(1);
    elseif numel(y_limits) > 2
        y_limits = y_limits(1:2);
    end
end

% Map lens (y_in,z_in) -> original (x_orig,y_orig)
x_orig = y + grid_center(1);      % original x
y_orig = z + grid_center(2);      % original y

% Keep evaluations inside the tabulated domain to avoid NaNs during the
% numerical intersection search.
if all(isfinite(x_limits))
    x_orig = min(max(x_orig, x_limits(1)), x_limits(2));
end
if all(isfinite(y_limits))
    y_orig = min(max(y_orig, y_limits(1)), y_limits(2));
end

if flag == 0
    % --- Return sag along x (lens axis): x = Z(x_orig, y_orig)
    x = F(x_orig, y_orig);
else
    % --- Return unit normal [nx, ny, nz] in lens coordinates
    Zx = Fdx(x_orig, y_orig);
    Zy = Fdy(x_orig, y_orig);

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
