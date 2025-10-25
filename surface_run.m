function varargout = examplesurface_lensRun()
%%
clear all; close all; clc;
load surfaceData1200.mat 
load surfMesh.mat
%% Plots only the surface at s = 1200
X = xMesh; Y = yMesh; Z = surfaceData1200;
clear xMesh yMesh surfaceData1200

%% Convert between meshgrid and ngrid formats
% Gridded interpolant uses NGRID format, so it's necessary to convert 
% https://se.mathworks.com/help/matlab/ref/ndgrid.html
% MESHGRID: X, Y
% NGRID: Xn, Yn

% Meshgrid -> ngrid
% Needs to be sorted to get the same surface
[xa, ix] = sort(X(1,:));
[ya, iy] = sort(Y(:,1));

% Unsorted NGRID is made like this, but is not used in this code
% [Xn, Yn] = ndgrid(xa, ya);

%% Interpolating and Compare surface normals
% To evaluate the surface at all points it is necessary to interpolate the
% surfae

% Evaluate Z on Ngrid
Za = Z(iy, ix);

% Interpolant built on ngrid
F = griddedInterpolant({xa, ya}, Za.', 'linear', 'none');  % F(X,Y)
clear Za

% Zi is teh interpolated surface
% Evaluate Interpolated surface
% Converting to Ngrid yield better performance. Keep '
Zi = F(X', Y')';  isequal(Zi, Z); % should equal Z (check).

%% SINGLE POINT EVALUATION
% It is now possible to evaluate both the height and the surface normal in
% an arbitrary point

[dZdx, dZdy] = gradient(Zi, xa, ya);          % X spacing first, then Y
Fdx = griddedInterpolant({ya, xa}, dZdx, 'linear');   % or 'makima'/'spline'
Fdy = griddedInterpolant({ya, xa}, dZdy, 'linear');


lens_args = {F, Fdx, Fdy};  % <-- these are passed to surface_lens as args

%% --- Build the bench (same layout as your example) ---
bench = Bench;

aperture = 80;  % mm
% Use 'air' to 'mirror' for a reflective test (no dispersion setup needed).
% For a transmissive lens, swap 'mirror' -> a glass name present in your material set (e.g., 'bk7').
elem = GeneralLens([0 0 0], aperture, 'surface_lens', { 'air' 'mirror' }, lens_args{:});
bench.append(elem);

% Screen downstream (along +X)
screen_distance = -20;   % mm along +X (negative because of how Screen is placed/rotated)
screen_size = 180;       % mm
screen = Screen([screen_distance 0 1], screen_size, screen_size, 512, 512);
screen.rotate([0 1 0], pi);   % face back toward the optic
bench.append(screen);

% Collimated beam aimed along +X
nrays = 100;
source_pos   = [-120 0 0];
incident_dir = [1 0 0];
beam_diam    = aperture * 0.95;
rays_in = Rays(nrays, 'collimated', source_pos, incident_dir, beam_diam, 'hexagonal');

fprintf('Tracing rays through surface_lens ...\n');
rays_out = bench.trace(rays_in);

% Visualize
bench.draw(rays_out, 'lines', [], 1.5);
title('GeneralLens using surface_lens (interpolated surface)', 'Color','w');

figure('Name','surface_lens screen capture','NumberTitle','Off');
imagesc(screen.image); axis image; colormap hot; colorbar;
set(gca,'YDir','normal');
title('Illumination after surface_lens'); xlabel('Screen Y bins'); ylabel('Screen Z bins');

if nargout >= 1, varargout{1} = screen; end
if nargout >= 2, varargout{2} = rays_out; end
if nargout >= 3, varargout{3} = bench; end
if nargout >= 4, varargout{4} = elem; end
end