function example17()
%
% Reflective free-surface gradient detector (FSGD) demonstration.
%
% This example builds a simple reflective setup that illuminates a
% bi-axial sinusoidal free-form surface and records the reflected ray
% distribution on a screen. The scene approximates the reflective mode of
% the FSGD technique.
%
% The surface profile is provided by sinusoidal_surface.m.
%
% Copyright: 2024 Optometrika contributors

% Create a container for optical elements
bench = Bench;

% Define a reflective sinusoidal surface. The surface is described by a
% sum of sine waves along the Y and Z axes. Adjust the amplitudes or
% periods to explore different gradients.
amp_y = 3;      % amplitude along Y (millimetres)
per_y = 40;     % period along Y
amp_z = 1.5;    % amplitude along Z
per_z = 25;     % period along Z
aperture = 80;  % clear aperture diameter

mirror = GeneralLens( [ 0 0 0 ], aperture, 'sinusoidal_surface', ...
    { 'air' 'mirror' }, amp_y, per_y, amp_z, per_z );
bench.append( mirror );

% Place a screen close to the focal region created by the sinusoidal sag.
% Positioning the screen nearer to the mirror (compared with the initial
% demonstration) makes the interference/fringe pattern clearly visible.
screen_distance = -60;
screen_size = 90;
screen = Screen( [ screen_distance 0 0 ], screen_size, screen_size, 512, 512 );
screen.rotate( [ 0 1 0 ], pi );
bench.append( screen );

% Generate a collimated bundle of rays aimed at the mirror. The bundle
% diameter is matched to the clear aperture of the surface.
nrays = 4000;
source_pos = [ -150 0 0 ];
incident_dir = [ 1 0 0 ];
rays_in = Rays( nrays, 'collimated', source_pos, incident_dir, aperture, 'hexagonal' );

fprintf( 'Tracing rays through the reflective sinusoidal surface...\n' );
rays_through = bench.trace( rays_in );

% Visualise the bench and ray paths.
bench.draw( rays_through, 'lines', [], 2 );
title( 'Reflective FSGD setup with sinusoidal free-form mirror', 'Color', 'w' );

% Display the intensity pattern on the capture screen.
figure( 'Name', 'FSGD reflective response', 'NumberTitle', 'Off' );
imagesc( screen.image );
axis image;
colormap hot;
colorbar;
set( gca, 'YDir', 'normal' );
title( 'Reflected pattern on the observation screen' );
xlabel( 'Screen Y bins' );
ylabel( 'Screen Z bins' );

% Build a continuous heat map to highlight the reflective valleys where the
% sinusoidal surface concentrates the rays. The Screen already accumulates a
% discrete histogram of ray intersections; here we apply a Gaussian smoothing
% filter to generate a continuous-looking density map and render it with
% MATLAB's heatmap visualisation for clearer interpretation.
heatmap_image = double( screen.image );
if any( heatmap_image( : ) )
    kernel_sigma = 2.0;
    kernel_size = 15; % odd value so that the kernel is centered
    kernel = gaussian_kernel( kernel_size, kernel_sigma );
    heatmap_smoothed = conv2( heatmap_image, kernel, 'same' );
else
    heatmap_smoothed = heatmap_image;
end

y_centres = linspace( -screen.w/2, screen.w/2, screen.wbins );
z_centres = linspace( -screen.h/2, screen.h/2, screen.hbins );

figure( 'Name', 'FSGD reflective heat map', 'NumberTitle', 'Off' );
hmap = heatmap( y_centres, z_centres, heatmap_smoothed );
hmap.Colormap = parula( 256 );
hmap.ColorbarVisible = 'on';
hmap.GridVisible = 'off';
hmap.CellLabelColor = 'none';
hmap.Title = 'Continuous heat map of reflected ray density';
hmap.XLabel = 'Screen Y (mm)';
hmap.YLabel = 'Screen Z (mm)';

end

function kernel = gaussian_kernel( size_px, sigma )
%GAUSSIAN_KERNEL Create a normalised 2-D Gaussian kernel.
half_size = ( size_px - 1 ) / 2;
[ x, y ] = meshgrid( -half_size : half_size, -half_size : half_size );
kernel = exp( -( x.^2 + y.^2 ) / ( 2 * sigma^2 ) );
kernel = kernel / sum( kernel( : ) );
