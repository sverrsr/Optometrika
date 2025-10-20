function exampleInterpolatedSagLens()
%EXAMPLEINTERPOLATEDSAGLENS Demonstrate the interpolatedSagLens profile.
%   This example fabricates a cosine-profile lens, samples it on a grid,
%   and then reuses the samples with interpolatedSagLens to trace rays
%   through a GeneralLens surface.
%
%   Run the script to see the lens surface, the ray paths, and the screen
%   irradiance formed by the synthetic profile.
%
%   See also INTERPOLATEDSAGLENS, GENERALLENS, COSLENS.

% Generate gridded samples of a smooth free-form profile. Here we reuse the
% cosine demonstration surface but any measured sag grid with the required
% fields will work just as well.
apertureRadius = 25e-3;              % 25 mm radius aperture
sampleCount    = 201;                % odd count ensures the optical axis lies on the grid
height         = 2e-3;               % 2 mm peak sag
period         = 2 * apertureRadius; % cosine period to roughly match the aperture

yAxis = linspace( -apertureRadius, apertureRadius, sampleCount );
zAxis = linspace( -apertureRadius, apertureRadius, sampleCount );
[ zMesh, yMesh ] = meshgrid( zAxis, yAxis );

surfaceSamples.surfaceData1200 = coslens( yMesh, zMesh, { height, period }, 0 );
surfaceSamples.xMesh          = zMesh;
surfaceSamples.yMesh          = yMesh;

% You can also save the samples to disk and pass a MAT-file name instead of
% the struct directly. Uncomment the lines below to exercise that path.
% dataPath = fullfile( tempdir, 'cosineLensSamples.mat' );
% save( dataPath, '-struct', 'surfaceSamples' );
% surfaceArg = { dataPath };

surfaceArg = { surfaceSamples };

% Inspect the interpolated sag / normal at the optical axis to verify the
% callback works outside the tracing loop.
centerSag = interpolatedSagLens( 0, 0, surfaceArg, 0 );
centerNormal = interpolatedSagLens( 0, 0, surfaceArg, 1 );
fprintf( 'Axis sag: %.6f m\n', centerSag );
fprintf( 'Axis normal: [%.4f %.4f %.4f]\n', centerNormal );

% Build a simple bench with the interpolated lens.
bench = Bench;
bench.append( Aperture( [ -40e-3 0 0 ], [ 0; 2 * apertureRadius ] ) );
bench.append( GeneralLens( [ 0 0 0 ], [ 0; 2 * apertureRadius ], ...
    'interpolatedSagLens', { 'air', 'bk7' }, surfaceArg{:} ) );
bench.append( Screen( [ 80e-3 0 0 ], 60e-3, 60e-3, 512, 512 ) );

% Launch a collimated bundle aimed down the +X axis.
raysIn = Rays( 1500, 'collimated', [ -120e-3 0 0 ], [ 1 0 0 ], ...
    2 * apertureRadius, 'hexagonal' );
raysThrough = bench.trace( raysIn );

% Visualise the traced system.
figure( 'Name', 'Interpolated Sag Lens Demo', 'NumberTitle', 'off' );
bench.draw( raysThrough, 'lines', [], [], 0 );
axis equal;
xlabel( 'X (m)' ); ylabel( 'Y (m)' ); zlabel( 'Z (m)' );
title( 'Cosine-profile lens reconstructed via interpolatedSagLens' );

% Display the irradiance pattern on the screen.
figure( 'Name', 'Screen Irradiance', 'NumberTitle', 'off' );
imagesc( bench.elem{ end }.image );
axis image;
colormap( gray );
colorbar;
title( 'Resulting spot on the screen' );

end
