function example17()
%EXAMPLE17 Demonstrate the interpolatedSagLens GeneralLens callback.
%   This example fabricates a smooth free-form surface on a rectilinear
%   grid, saves it to a MAT-file, and traces collimated rays through a lens
%   that uses the interpolated sag profile for its front surface.
%
%   Running the script will produce two figures: the first plots the sag
%   samples used for interpolation, and the second shows the traced ray
%   paths together with the screen image near focus.
%
%   See also INTERPOLATEDSAGLENS.

% Location for the demonstration surface data.
dataFile = fullfile( fileparts( mfilename( 'fullpath' ) ), ...
    'demoInterpolatedSagSurface.mat' );

% Build the dataset on demand so the example stays self-contained.
if ~isfile( dataFile )
    % Define a square grid spanning a 50 mm diameter aperture.
    radius = 25; % mm
    yAxis = linspace( -radius, radius, 161 );
    zAxis = linspace( -radius, radius, 161 );
    [ yMesh, xMesh ] = ndgrid( yAxis, zAxis );

    % Create a gently aspheric sag profile with a bit of astigmatism.
    baseRadius = 120; % mm tangent sphere radius
    sagSphere = ( yMesh.^2 + xMesh.^2 ) ./ ( 2 * baseRadius );
    astigmatism = 0.2e-3 * ( xMesh.^2 - yMesh.^2 ) / radius^2;
    surfaceData1200 = sagSphere + astigmatism;

    save( dataFile, 'surfaceData1200', 'xMesh', 'yMesh' );
end

% Visualise the samples so you can confirm they look sensible.
surface = load( dataFile );
figure( 'Name', 'Interpolated sag samples', 'NumberTitle', 'off' );
surf( surface.xMesh, surface.yMesh, surface.surfaceData1200 );
shading interp;
xlabel( 'Z (mm)' );
ylabel( 'Y (mm)' );
zlabel( 'Sag X (mm)' );
title( 'Demo sag surface used by interpolatedSagLens' );
view( -35, 35 );
axis equal tight;

% Build a small optical bench that uses the interpolated surface.
bench = Bench;

% Aperture matching the data grid so stray rays get clipped.
bench.append( Aperture( [ -60 0 0 ], [ 0 50 ] ) );

% Front free-form surface: air -> N-BK7 using the interpolated sag data.
front = GeneralLens( [ 0 0 0 ], [ 0 50 ], 'interpolatedSagLens', ...
    { 'air' 'bk7' }, dataFile );

% Simple spherical back surface (BK7 -> air) to complete the lens.
back = Lens( [ 8 0 0 ], [ 0 50 ], -120, 0, { 'bk7' 'air' } );
bench.append( { front, back } );

% Screen to observe the focus.
screen = Screen( [ 80 0 0 ], 60, 60, 256, 256 );
bench.append( screen );

% Launch a bundle of collimated rays aimed along +X.
nrays = 2000;
raysIn = Rays( nrays, 'collimated', [ -120 0 0 ], [ 1 0 0 ], 50, 'hexagonal' );

% Trace and display the results.
tic;
raysThrough = bench.trace( raysIn );
traceTime = toc;
fprintf( 'Ray tracing finished in %.2f s.\n', traceTime );

% Draw the optical system along with the ray paths.
figure( 'Name', 'Interpolated sag lens bench', 'NumberTitle', 'off' );
bench.draw( raysThrough, 'lines' );
title( 'interpolatedSagLens demonstration system' );

% Show the screen irradiance map.
figure( 'Name', 'Screen image', 'NumberTitle', 'off' );
imshow( screen.image, [] );
title( 'Screen irradiance at the default distance' );
colorbar;

end
