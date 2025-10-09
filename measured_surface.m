function x = measured_surface( y, z, args, flag )
%MEASURED_SURFACE Interpolated mirror sag from measured samples.
%
%   X = MEASURED_SURFACE( Y, Z, ARGS, FLAG ) implements the surface
%   interface expected by GeneralLens for a mirror whose sag is described by
%   dense measurements on a rectangular grid. The first entry of ARGS must
%   be a struct with the fields:
%       YGrid - vector of monotonically increasing Y coordinates (rows)
%       ZGrid - vector of monotonically increasing Z coordinates (columns)
%       Sag   - 2-D matrix of sag values (size numel(YGrid) x numel(ZGrid))
%
%   When FLAG == 0 the function returns interpolated sag values evaluated at
%   the supplied Y and Z coordinates. Otherwise it returns the corresponding
%   surface normals pointing along +X, computed via gradients of the sag
%   surface. Linear interpolation with nearest extrapolation is employed so
%   that rays outside the sampled grid still interact smoothly.
%
%   See also: MEASURED_SURFACE_DATASET, EXAMPLE17_MEASURED
%
% Copyright: 2024 Optometrika contributors

% Retrieve dataset from the arguments
if isempty( args )
    error( 'Measured surface dataset missing. Pass a struct as args{1}.' );
end
data = args{ 1 };

required_fields = { 'YGrid', 'ZGrid', 'Sag' };
for idx = 1:numel( required_fields )
    if ~isfield( data, required_fields{ idx } )
        error( 'Measured surface dataset must contain field %s.', required_fields{ idx } );
    end
end

% Cache interpolants for repeated calls. This significantly reduces the
% overhead during ray tracing where the function may be invoked thousands of
% times.
persistent sag_interp dfdY_interp dfdZ_interp cached_hash

% Construct a lightweight hash based on vector sizes to detect dataset
% changes. This avoids expensive deep comparisons for every call.
current_hash = [ numel( data.YGrid ), numel( data.ZGrid ), numel( data.Sag ) ];
if isempty( sag_interp ) || isempty( cached_hash ) || any( cached_hash ~= current_hash )
    sag_interp = griddedInterpolant( { data.YGrid, data.ZGrid }, data.Sag, 'linear', 'nearest' );
    [dFdY, dFdZ] = gradient( data.Sag, data.YGrid, data.ZGrid );
    dfdY_interp = griddedInterpolant( { data.YGrid, data.ZGrid }, dFdY, 'linear', 'nearest' );
    dfdZ_interp = griddedInterpolant( { data.YGrid, data.ZGrid }, dFdZ, 'linear', 'nearest' );
    cached_hash = current_hash;
end

if flag == 0
    x = sag_interp( y, z );
else
    dfd_y = dfdY_interp( y, z );
    dfd_z = dfdZ_interp( y, z );

    dfd_y = dfd_y( : );
    dfd_z = dfd_z( : );
    ones_vec = ones( numel( dfd_y ), 1 );
    normals = [ ones_vec, -dfd_y, -dfd_z ];
    normals = normals ./ sqrt( sum( normals.^2, 2 ) );

    x = normals;
end
end
