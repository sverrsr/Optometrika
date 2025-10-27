function x = surface_lens(y, z, args, flag)
    F   = args{1};   % Z(x,y)
    Fdx = args{2};   % dZ/dx,  called as Fdx(y,x)
    Fdy = args{3};   % dZ/dy,  called as Fdy(y,x)

    arg_idx = 4;
    grid_center = [0, 0];
    if numel(args) >= arg_idx && ~isempty(args{arg_idx})
        gc = double(args{arg_idx}(:).'); grid_center = [gc(1) (numel(gc)>1)*gc(2)];
        arg_idx = arg_idx + 1;
    end

    % THESE LIMITS SHOULD DEFINE YOUR *CLEAR APERTURE* (full widths)
    x_limits = [-inf, inf];
    y_limits = [-inf, inf];
    if numel(args) >= arg_idx && ~isempty(args{arg_idx}), x_limits = double(args{arg_idx}(:).'); arg_idx = arg_idx + 1; end
    if numel(args) >= arg_idx && ~isempty(args{arg_idx}), y_limits = double(args{arg_idx}(:).'); end

    % Map lens (y,z) -> original (x,y)
    x_orig = y + grid_center(1);
    y_orig = z + grid_center(2);

    % Rectangular *inside* test in LENS coordinates (no clamping!)
    y_min = x_limits(1) - grid_center(1);  y_max = x_limits(2) - grid_center(1);
    z_min = y_limits(1) - grid_center(2);  z_max = y_limits(2) - grid_center(2);
    inside = (y >= y_min) & (y <= y_max) & (z >= z_min) & (z <= z_max);

    if flag == 0
        x = nan(size(y), 'like', y);
        if any(inside(:))
            x(inside) = F(x_orig(inside), y_orig(inside));
        end
    else
        nx = nan(size(y), 'like', y);
        ny = nan(size(y), 'like', y);
        nz = nan(size(y), 'like', y);
        if any(inside(:))
            Zx = Fdx(y_orig(inside), x_orig(inside));
            Zy = Fdy(y_orig(inside), x_orig(inside));
            c  = 1 ./ sqrt(1 + Zx.^2 + Zy.^2);
            nx(inside) = c;           % = n_x (lens coords)
            ny(inside) = -Zx .* c;
            nz(inside) = -Zy .* c;
        end
        % Orient ~+x, safe with NaNs
        flipmask = nx < 0;
        nx(flipmask) = -nx(flipmask);
        ny(flipmask) = -ny(flipmask);
        nz(flipmask) = -nz(flipmask);
        x = [nx, ny, nz];
    end
end
