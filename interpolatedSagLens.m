function out = interpolatedSagLens( y, z, args, flag )
%INTERPOLATEDSAGLENS Evaluate a free-form lens defined by gridded samples.
%   OUT = INTERPOLATEDSAGLENS(Y, Z, ARGS, FLAG) implements the callback
%   contract expected by GeneralLens. The first two inputs specify the
%   coordinates in the lens plane (metres). ARGS must supply either a path
%   to a MAT-file containing the fields `surfaceData1200`, `xMesh`, and
%   `yMesh`, or a struct with those fields already loaded. When FLAG == 0
%   the interpolated sag is returned. Otherwise the routine returns unit
%   normals oriented predominantly along +X, estimated via centred finite
%   differences of the interpolant.
%
%   A second optional entry in ARGS can override the finite-difference
%   spacing used for the normal estimation.
%
%   Example usage:
%       lens = GeneralLens([0 0 0], [0 0.05], 'interpolatedSagLens', ...
%                          {'mySurface.mat'}, {'air','bk7'});
%
%   See also GENERAL_LENS, GRIDDEDINTERPOLANT.

persistent F yAxis zAxis fdStep cachedArgs

if nargin < 4
    error( 'interpolatedSagLens:NotEnoughInputs', ...
        'Expected the signature interpolatedSagLens(y,z,args,flag).' );
end

if isempty( args )
    error( 'interpolatedSagLens:MissingData', ...
        'ARGS must contain the sampled surface data or a MAT-file name.' );
end

needsRefresh = isempty( F ) || isempty( cachedArgs ) || ~isequal( cachedArgs, args );

if needsRefresh
    surface = args{ 1 };
    if ischar( surface ) || ( isstring( surface ) && isscalar( surface ) )
        surface = load( surface );
    elseif ~isstruct( surface )
        error( 'interpolatedSagLens:BadData', ...
            'ARGS{1} must be a struct with surface samples or a MAT-file name.' );
    end

    requiredFields = { 'surfaceData1200', 'xMesh', 'yMesh' };
    for idx = 1:numel( requiredFields )
        if ~isfield( surface, requiredFields{ idx } )
            error( 'interpolatedSagLens:MissingField', ...
                'Surface data is missing the "%s" field.', requiredFields{ idx } );
        end
    end

    sag = double( surface.surfaceData1200 );
    xMesh = double( surface.xMesh );
    yMesh = double( surface.yMesh );

    if ~isequal( size( sag ), size( xMesh ), size( yMesh ) )
        error( 'interpolatedSagLens:SizeMismatch', ...
            'surfaceData1200, xMesh, and yMesh must have identical sizes.' );
    end

    yAxis = yMesh( :, 1 );
    zAxis = xMesh( 1, : );

    if any( diff( yAxis ) <= 0 ) || any( diff( zAxis ) <= 0 )
        error( 'interpolatedSagLens:NonMonotonicGrid', ...
            'Surface samples must form a monotonic grid in both dimensions.' );
    end

    F = griddedInterpolant( { yAxis, zAxis }, sag, 'linear', 'none' );

    dy = median( abs( diff( yAxis ) ) );
    dz = median( abs( diff( zAxis ) ) );
    fdStep = 0.5 * min( dy, dz );
    if ~isfinite( fdStep ) || fdStep <= 0
        fdStep = 1e-6;
    end

    cachedArgs = args;
end

if numel( args ) >= 2 && ~isempty( args{ 2 } )
    fd = args{ 2 };
else
    fd = fdStep;
end

if flag == 0
    out = F( y, z );
    return;
end

yp = y + fd;
yh = y - fd;
zp = z + fd;
zh = z - fd;

dx_dy = ( F( yp, z ) - F( yh, z ) ) ./ ( 2 * fd );
dx_dz = ( F( y, zp ) - F( y, zh ) ) ./ ( 2 * fd );

nx = ones( size( dx_dy ) );
ny = -dx_dy;
nz = -dx_dz;

mag = sqrt( nx.^2 + ny.^2 + nz.^2 );
mag( mag == 0 ) = 1;

nx = nx ./ mag;
ny = ny ./ mag;
nz = nz ./ mag;

out = [ nx( : ), ny( : ), nz( : ) ];
end
