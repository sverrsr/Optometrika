clear all
close all
clc

[X,Y] = meshgrid(-8:.5:8);
R = sqrt(X.^2 + Y.^2) + eps;
Z = sin(R)./R;

nrays = 100;

bench = Bench;

% Vil ha inn X, Y og Z
y = [ 0 0 0 ]; % Initial position
aperture = 120;

mirror = GeneralLens( [ 0 0 0 ], aperture, 'SelfDefinedPlane', ...
    { 'air' 'mirror' }, X, Y, Z);

bench.append( mirror );

bench.draw(); %  20, 'lines', [], 2

nrays = 100;
source_pos = [ -150 0 0 ];
incident_dir = [ 1 0 0 ];
bundle_diameter = aperture;
rays_in = Rays( nrays, 'collimated', source_pos, incident_dir, bundle_diameter, 'hexagonal' );

rays_through = bench.trace( rays_in );

% Visualise the bench and ray paths.
bench.draw(); % rays_through, 'lines', [], 2 



%%
% Create a container for optical elements
bench = Bench;

mirror = GeneralLens( [ 0 0 0 ], 20, 'SelfDefinedPlane', ...
    { 'air' 'mirror' }, Z);
bench.append( mirror );

% Place a screen close to the focal region created by the sinusoidal sag.
% Positioning the screen nearer to the mirror (compared with the initial
% demonstration) makes the interference/fringe pattern clearly visible.
% % screen_distance = -15;
% % 
% % % Match the screen extent to the mirror diameter so that the captured
% % % heat-map can fill the frame when the mirror aperture is increased.
% % screen_size = aperture;
% % screen = Screen( [ screen_distance 0 0 ], screen_size, screen_size, 512, 512 );
% % screen.rotate( [ 0 1 0 ], pi );
% % bench.append( screen );

% Generate a collimated bundle of rays aimed at the mirror. The bundle
% diameter is matched to the clear aperture of the surface. Increase both
% the aperture and bundle diameter together to enlarge the mirror footprint.
% nrays = 6000;
% source_pos = [ -150 0 0 ];
% incident_dir = [ 1 0 0 ];
% bundle_diameter = 20;
% rays_in = Rays( nrays, 'collimated', source_pos, incident_dir, bundle_diameter, 'hexagonal' );

fprintf( 'Tracing rays through the reflective sinusoidal surface...\n' );
% rays_through = bench.trace( rays_in );

% Visualise the bench and ray paths.
bench.draw( 20, 'lines', [], 2 );
title( 'Reflective FSGD setup with sinusoidal free-form mirror', 'Color', 'w' );
