function varargout = example17_measured()
%
% Reflective free-surface gradient detector (FSGD) with measured mirror.
%
% This example mirrors example17 but replaces the analytical sinusoidal
% profile with a dense grid of "measured" sag points. The surface is
% interpolated at runtime, allowing you to experiment with arbitrary free-
% form datasets acquired from a coordinate measurement machine. The
% generated setup directs a collimated bundle of rays onto the mirror and
% captures the reflected intensity on a screen.
%
% Call the example with output arguments, e.g.:
%   [screen, rays, bench, mirror] = example17_measured();
% to inspect the simulated results after the figures are rendered.
%
% Copyright: 2024 Optometrika contributors

bench = Bench;

% Load the synthetic "measured" dataset. Replace this call with your own
% data loading routine (e.g. loading a MAT-file) when working with actual
% measurement points.
data = measured_surface_dataset();

% The sampling spans +/-50 mm along Y and +/-40 mm along Z, so choose an
% aperture that comfortably covers the available data. The GeneralLens is
% configured as a reflective surface.
aperture = 100;  % millimetres
mirror = GeneralLens( [ 0 0 0 ], aperture, 'measured_surface', { 'air', 'mirror' }, data );
bench.append( mirror );

% Place a screen close to the region where the reflected bundle converges.
screen_distance = -20;  % millimetres
screen_size = 90;
screen = Screen( [ screen_distance 0 0 ], screen_size, screen_size, 512, 512 );
screen.rotate( [ 0 1 0 ], pi );
bench.append( screen );

% Launch a collimated bundle matched to the mirror aperture.
nrays = 4000;
source_pos = [ -35 0 0 ];
incident_dir = [ 1 0 0 ];
rays_in = Rays( nrays, 'collimated', source_pos, incident_dir, aperture, 'hexagonal' );

fprintf( 'Tracing rays through the reflective measured surface...\n' );
rays_through = bench.trace( rays_in );

% Visualise the bench and ray paths.
bench.draw( rays_through, 'lines', [], 2 );
title( 'Reflective FSGD setup with measured free-form mirror', 'Color', 'w' );

% Display the intensity pattern on the capture screen.
figure( 'Name', 'FSGD measured mirror response', 'NumberTitle', 'Off' );
imagesc( screen.image );
axis image;
colormap hot;
colorbar;
set( gca, 'YDir', 'normal' );
title( 'Reflected pattern on the observation screen' );
xlabel( 'Screen Y bins' );
ylabel( 'Screen Z bins' );

if nargout >= 1
    varargout{ 1 } = screen;
end
if nargout >= 2
    varargout{ 2 } = rays_through;
end
if nargout >= 3
    varargout{ 3 } = data;
end
if nargout >= 4
    varargout{ 4 } = bench;
end
if nargout >= 5
    varargout{ 5 } = mirror;
end

end
