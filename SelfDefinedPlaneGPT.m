function out = SelfDefinedPlaneGPT( y, z, args, flag )
%SELFDEFINEDPLANE Surface based on sampled sag values on a rectangular grid.
%
%   X = SELFDEFINEDPLANE( Y, Z, ARGS, FLAG ) implements the interface
%   expected by the GeneralLens class. The function returns the sag (X
%   coordinate) or surface normals of a user supplied free-form surface
%   defined on a regular Y/Z grid. The surface description can be supplied
%   in one of the following ways via the ARGS cell array:
%       ARGS{1} - structure with fields:
%           y   - vector of Y coordinates (length Ny)
%           z   - vector of Z coordinates (length Nz)
%           sag - Ny-by-Nz matrix of surface sag values expressed along X
%       ARGS{1:3} - the Y coordinates, Z coordinates and sag matrix. The
%           coordinate arrays can be either vectors or grids created with
%           NDGRID or MESHGRID. When grids are supplied the first column/
%           row is used to extract the axis vectors.
%
%   When FLAG == 0 the function returns the sag evaluated at the supplied Y
%   and Z coordinates. Otherwise it returns a matrix of surface normals
%   pointing in the +X direction.
%
%   The interpolation uses 'linear' interpolation inside the tabulated
%   domain and 'nearest' extrapolation outside the domain.
%
%   Example:
%       [yGrid, zGrid] = ndgrid(-10:0.5:10);
%       R = sqrt(yGrid.^2 + zGrid.^2) + eps;
%       sag = sin(R) ./ R;
%       mirror = GeneralLens([0 0 0], 20, 'SelfDefinedPlane', {'air' 'mirror'}, ...
%           yGrid(:,1), zGrid(1,:), sag);
%
%   Copyright: 2024 Optometrika contributors

if nargin == 1
    % Allow quick validation helper: SelfDefinedPlane(dataStruct)
    out = validateSurfaceData( parseSurfaceArgs( { y } ) );
    return;
end

if nargin < 4
    flag = 0;
end
if nargin < 3 || isempty( args )
    error( 'SelfDefinedPlane:MissingData', ...
        'Surface data must be provided via the ARGS cell array.' );
end

surface = parseSurfaceArgs( args );
surface = validateSurfaceData( surface );

% Build interpolants for the sag and its first derivatives.
valueInterp = griddedInterpolant( { surface.y, surface.z }, surface.sag, ...
    'linear', 'nearest' );

yQuery = y( : );
zQuery = z( : );

if flag == 0
    values = valueInterp( yQuery, zQuery );
    out = reshape( values, size( y ) );
    return;
end

dfdyInterp = griddedInterpolant( { surface.y, surface.z }, surface.dfdy, ...
    'linear', 'nearest' );
dfdzInterp = griddedInterpolant( { surface.y, surface.z }, surface.dfdz, ...
    'linear', 'nearest' );

dfdy = dfdyInterp( yQuery, zQuery );
dfdz = dfdzInterp( yQuery, zQuery );

onesVec = ones( numel( dfdy ), 1 );
normals = [ onesVec, -dfdy, -dfdz ];
normals = normals ./ sqrt( sum( normals.^2, 2 ) );

nanMask = isnan( normals );
if any( nanMask, 'all' )
    normals( nanMask ) = 0;
end

out = normals;

end

function surface = parseSurfaceArgs( args )
%PARSURFACEARGS Normalise input arguments to a surface data structure.

if numel( args ) == 1 && isstruct( args{ 1 } )
    surface = args{ 1 };
    return;
end

if numel( args ) < 3
    error( 'SelfDefinedPlane:MissingData', ...
        'Provide either a surface structure or Y, Z, sag arrays.' );
end

yData = args{ 1 };
zData = args{ 2 };
sag = args{ 3 };

if ~isnumeric( sag ) || ~isreal( sag )
    error( 'SelfDefinedPlane:InvalidSag', 'Sag values must be real numeric data.' );
end

if isvector( yData )
    yVec = yData( : );
elseif isnumeric( yData ) && size( yData, 2 ) >= 1
    yVec = yData( :, 1 );
else
    error( 'SelfDefinedPlane:InvalidY', ...
        'Y coordinate data must be a vector or a grid with at least one column.' );
end

if isvector( zData )
    zVec = zData( : ).';
elseif isnumeric( zData ) && size( zData, 1 ) >= 1
    zVec = zData( 1, : );
else
    error( 'SelfDefinedPlane:InvalidZ', ...
        'Z coordinate data must be a vector or a grid with at least one row.' );
end

surface = struct( 'y', yVec, 'z', zVec, 'sag', sag );

end

function data = validateSurfaceData( data )
%VALIDATESURFACEDATA Normalise and pre-compute derivatives for a surface.

requiredFields = { 'y', 'z', 'sag' };
for k = 1 : numel( requiredFields )
    if ~isfield( data, requiredFields{ k } )
        error( 'SelfDefinedPlane:MissingField', ...
            'Surface data structure must contain the field ''%s''.', requiredFields{ k } );
    end
end

yVec = data.y(:);
zVec = data.z(:).';
sag = data.sag;

if ~ismatrix( sag ) || size( sag, 1 ) ~= numel( yVec ) || size( sag, 2 ) ~= numel( zVec )
    error( 'SelfDefinedPlane:SizeMismatch', ...
        'Surface sag matrix must have size [%d %d].', numel( yVec ), numel( zVec ) );
end

if ~issorted( yVec ) || ~issorted( zVec )
    error( 'SelfDefinedPlane:MonotonicGrid', ...
        'Y and Z coordinate vectors must be monotonically increasing.' );
end

% Determine spacing for gradient computation.
dy = gradientSpacing( yVec );
dz = gradientSpacing( zVec );
[dfdy, dfdz] = gradient( sag, dy, dz );

data.y = yVec;
data.z = zVec;
data.sag = sag;
data.dfdy = dfdy;
data.dfdz = dfdz;

end

function h = gradientSpacing( vec )
%GRADIENTSPACING Return spacing argument for gradient().
if numel( vec ) <= 1
    h = 1;
    return;
end
steps = diff( vec );
if all( abs( steps - steps( 1 ) ) < eps( steps( 1 ) ) * 10 )
    h = steps( 1 );
else
    h = vec;
end
if ~isscalar( h ) && size( h, 1 ) < size( h, 2 )
    h = h.';
end
end