function lensData = prepare_fourier_lens( surfaceData, xMesh, yMesh, varargin )
%PREPARE_FOURIER_LENS Create a Fourier-smoothed lens surface representation.
%   lensData = PREPARE_FOURIER_LENS(surfaceData, xMesh, yMesh) produces a
%   structure that can be consumed by the FOURIERLENS surface function used
%   with GeneralLens. The input matrices must be of the same size and
%   describe the surface sag (surfaceData) sampled on a rectangular grid
%   defined by xMesh and yMesh.
%
%   lensData = PREPARE_FOURIER_LENS(..., 'Cutoff', CUTOFF) specifies the
%   half-width of the low-pass window retained in the Fourier domain. A
%   scalar value keeps the same number of harmonics in both directions,
%   while a two-element vector [Cy Cz] controls the number of harmonics in
%   the y- and z-directions independently. The default keeps one quarter of
%   the spectrum along each dimension.
%
%   lensData = PREPARE_FOURIER_LENS(..., 'Method', METHOD) chooses the
%   interpolation method used when sampling the surface. The default method
%   is 'linear'.
%
%   The returned structure stores the filtered sag values along with their
%   gradients so that FOURIERLENS can evaluate both the sag and the surface
%   normals required by the tracing routines.
%
%   Example:
%       data = load('lensSample.mat');
%       lensInfo = prepare_fourier_lens(data.surfaceData1200, ...
%                                      data.xMesh, data.yMesh, ...
%                                      'Cutoff', [40 40]);
%       lens = GeneralLens([0 0 0], 58, 'fourierlens', {'air' 'bk7'}, lensInfo);
%
%   See also FOURIERLENS, GENERALLENS, FFT2, IFFT2, GRADIENT, INTERP2.
%
%   Copyright: Adapted for Optometrika contributors, 2024
%
parser = inputParser;
parser.FunctionName = 'prepare_fourier_lens';
parser.addParameter( 'Cutoff', [], @(v) isempty( v ) || isnumeric( v ) && ( isscalar( v ) || numel( v ) == 2 ) );
parser.addParameter( 'Method', 'linear', @(s) ischar( s ) || ( isstring( s ) && isscalar( s ) ) );
parser.parse( varargin{:} );

cutoff = parser.Results.Cutoff;
method = char( parser.Results.Method );

if ~ismatrix( surfaceData ) || ~ismatrix( xMesh ) || ~ismatrix( yMesh )
    error( 'prepare_fourier_lens:InvalidInput', 'Input data must be two-dimensional matrices.' );
end
if ~isequal( size( surfaceData ), size( xMesh ), size( yMesh ) )
    error( 'prepare_fourier_lens:SizeMismatch', 'Input matrices must share the same size.' );
end

[ny, nz] = size( surfaceData );
if isempty( cutoff )
    cutoff = [ floor( ny / 4 ), floor( nz / 4 ) ];
elseif isscalar( cutoff )
    cutoff = repmat( floor( cutoff ), 1, 2 );
else
    cutoff = floor( cutoff( 1:2 ) );
end

cutoff = max( cutoff, [ 0 0 ] );

if any( cutoff >= [ ny nz ] )
    warning( 'prepare_fourier_lens:CutoffTooLarge', ...
        'Cutoff exceeds spectrum size. Using full spectrum instead.' );
    cutoff = [ ny nz ];
end

% Fourier transform and spectral windowing
spect = fftshift( fft2( surfaceData ) );
mask = false( ny, nz );
cy = floor( ny / 2 ) + 1;
cz = floor( nz / 2 ) + 1;
yr = max( 1, cy - cutoff( 1 ) ) : min( ny, cy + cutoff( 1 ) );
zr = max( 1, cz - cutoff( 2 ) ) : min( nz, cz + cutoff( 2 ) );
mask( yr, zr ) = true;
spect( ~mask ) = 0;
filtered = real( ifft2( ifftshift( spect ) ) );

% Grid description
yGrid = yMesh;
zGrid = xMesh;

yCoords = unique( yGrid( :, 1 ) );
zCoords = unique( zGrid( 1, : ) );

if numel( yCoords ) > 1
    dy = median( diff( yCoords ) );
else
    dy = 1;
end

if numel( zCoords ) > 1
    dz = median( diff( zCoords ) );
else
    dz = 1;
end

[gradY, gradZ] = gradient( filtered, dy, dz );

lensData = struct( ...
    'yGrid', yGrid, ...
    'zGrid', zGrid, ...
    'sag', filtered, ...
    'gradY', gradY, ...
    'gradZ', gradZ, ...
    'method', method );
end
