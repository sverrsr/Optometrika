function out = fourierlens( y, z, args, flag )
%FOURIERLENS Evaluate a Fourier-smoothed free-form lens surface.
%   This surface function is meant to be used with GeneralLens. It expects a
%   data structure produced by PREPARE_FOURIER_LENS as the first element of
%   the argument cell array.
%
%   x = FOURIERLENS(y, z, args, 0) returns the surface sag evaluated at the
%   (y, z) coordinates supplied in meters.
%
%   n = FOURIERLENS(y, z, args, 1) returns surface normals pointing along
%   the positive x-direction. Each row of n corresponds to the normal at the
%   respective query location. Points outside the support of the measured
%   data return NaNs.
%
%   Additional optional arguments may follow the data structure: the second
%   element selects the interpolation method passed to INTERP2, overriding
%   the default stored in the structure.
%
%   See also PREPARE_FOURIER_LENS, INTERP2, GRADIENT, GENERALLENS.
%
if isempty( args )
    error( 'fourierlens:MissingData', ...
        'FOURIERLENS expects lens data produced by PREPARE_FOURIER_LENS.' );
end

data = args{ 1 };

if isfield( data, 'method' )
    method = char( data.method );
else
    method = 'linear';
end

if numel( args ) > 1 && ~isempty( args{ 2 } )
    method = char( args{ 2 } );
end

yq = y;
zq = z;

if flag == 0
    out = interp2( data.zGrid, data.yGrid, data.sag, zq, yq, method, NaN );
    return;
end

gradY = interp2( data.zGrid, data.yGrid, data.gradY, zq, yq, method, NaN );
gradZ = interp2( data.zGrid, data.yGrid, data.gradZ, zq, yq, method, NaN );

nx = ones( size( gradY ) );
ny = -gradY;
nz = -gradZ;

normals = [ nx( : ), ny( : ), nz( : ) ];
mag = sqrt( sum( normals.^2, 2 ) );

% Avoid division by zero while keeping NaNs for points outside the grid
valid = mag > 0;
normals( valid, : ) = normals( valid, : ) ./ mag( valid );
normals( ~valid, : ) = NaN;

out = normals;
end
