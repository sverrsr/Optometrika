function example17()
%EXAMPLE17 Construct a Fourier-based general lens from measured sag data.
%   This example demonstrates how to turn a grid of measured (and noisy)
%   sag values into a GeneralLens surface by smoothing the data in the
%   Fourier domain. The resulting lens is then visualized alongside the
%   original measurements.
%
% Copyright: Adapted for Optometrika contributors, 2024

rng( 0 ); % keep the synthetic "measurement" reproducible

% Create a synthetic free-form lens sag profile on a regular grid (meters)
yRange = linspace( -0.015, 0.015, 101 );
zRange = linspace( -0.015, 0.015, 101 );
[zGrid, yGrid] = meshgrid( zRange, yRange );

% Define a smooth target surface and contaminate it with measurement noise
trueSag = 2.5e-3 * exp( - ( ( yGrid / 0.009 ).^2 + ( zGrid / 0.009 ).^2 ) );
trueSag = trueSag + 3.5e-4 * cos( 6 * pi * yGrid ) .* cos( 4 * pi * zGrid );
noisySag = trueSag + 5e-5 * randn( size( trueSag ) );

% Prepare the Fourier-smoothed sag grid and gradient data
lensData = prepare_fourier_lens( noisySag, zGrid, yGrid, 'Cutoff', [ 18 18 ] );

% Build a GeneralLens surface from the preprocessed data
% Match the grid's footprint (30 mm diameter expressed in meters)
lensDiameter = 0.03; % m
lens = GeneralLens( [ 0 0 0 ], lensDiameter, 'fourierlens', { 'air' 'pmma' }, lensData );

% Visualize the raw measurements against the smoothed surface
figure;
subplot( 1, 2, 1 );
surf( zGrid * 1e3, yGrid * 1e3, noisySag * 1e3, 'EdgeColor', 'none' );
title( 'Measured sag (noisy)' );
xlabel( 'z (mm)' );
ylabel( 'y (mm)' );
zlabel( 'x (mm)' );
view( 45, 30 );
axis tight;
colormap parula;
colorbar;

subplot( 1, 2, 2 );
surf( lensData.zGrid * 1e3, lensData.yGrid * 1e3, lensData.sag * 1e3, 'EdgeColor', 'none' );
title( 'Fourier-smoothed sag' );
xlabel( 'z (mm)' );
ylabel( 'y (mm)' );
zlabel( 'x (mm)' );
view( 45, 30 );
axis tight;
colormap parula;
colorbar;

% Draw the resulting GeneralLens to inspect the surface normals visually
figure;
lens.draw( [ 0.5 0.8 1 0.6 ] );
axis equal;
xlabel( 'x (m)' );
ylabel( 'y (m)' );
zlabel( 'z (m)' );
title( 'GeneralLens built from Fourier-smoothed sag' );

end
