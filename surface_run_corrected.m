function varargout = examplesurface_lensRun_corrected()
%%
% Corrected runner for the interpolated surface lens demo. Builds the
% interpolants with consistent axis ordering so the surface normals are
% aligned with the underlying geometry.

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

% Surface bounds (in the original mesh units)
x_limits = [xa(1), xa(end)];
y_limits = [ya(1), ya(end)];
grid_center = [mean(x_limits), mean(y_limits)];
half_span = 0.5 * [diff(x_limits), diff(y_limits)];

% Leave a small buffer (half of the smallest grid spacing) so the optimizer
% never evaluates the interpolant exactly at the edge, where it would need to
% extrapolate.  This prevents NaNs at the surface boundary.
dx = diff(xa);
dy = diff(ya);
dx_min = min(dx(:));
dy_min = min(dy(:));
if isempty(dx_min) || isempty(dy_min) || ~isfinite(dx_min) || ~isfinite(dy_min)
    error('surface_run:InvalidGrid', 'Surface grid must contain at least two unique samples per axis.');
end
min_spacing = min([dx_min, dy_min]);
edge_buffer = 0.5 * min_spacing;

usable_half_span = half_span - edge_buffer;
if any(usable_half_span <= 0)
    error('surface_run:InvalidSurfaceBounds', ...
        'Surface data has insufficient span once edge buffer is removed.');
end

% Rectangular clear aperture dimensions in lens coordinates (Y,Z)
% Lens Y corresponds to the original X axis, and lens Z to the original Y axis.
lens_span_y = diff(x_limits);
lens_span_z = diff(y_limits);

% Sag limits (used to place the screen/source with margin)
z_limits = [min(Z(:)), max(Z(:))];
lens_depth = diff(z_limits);

% Unsorted NGRID is made like this, but is not used in this code
% [Xn, Yn] = ndgrid(xa, ya);

%% Interpolating and Compare surface normals
% To evaluate the surface at all points it is necessary to interpolate the
% surface

% Evaluate Z on Ngrid
Za = Z(iy, ix);

% Interpolant built on ngrid
F = griddedInterpolant({xa, ya}, Za.', 'linear', 'none');  % F(X,Y)

% Zi is the interpolated surface
% Evaluate Interpolated surface
% Converting to Ngrid yields better performance.
Zi = F(X', Y')';  isequal(Zi, Z); % should equal Z (check).

%% SINGLE POINT EVALUATION
% It is now possible to evaluate both the height and the surface normal in
% an arbitrary point

% Compute slopes directly on the sorted ndgrid (Za) so the coordinate vectors
% provided to GRADIENT align with the matrix dimensions.  The first output is
% ∂Z/∂y (rows correspond to ya) and the second is ∂Z/∂x (columns correspond to xa).
[dZdy_nd, dZdx_nd] = gradient(Za, ya, xa);

% griddedInterpolant expects the first grid vector to map to rows, therefore we
% transpose the slope arrays to obtain functions evaluated as F*(x, y).
Fdx = griddedInterpolant({xa, ya}, dZdx_nd.', 'linear', 'none');   % dZ/dx evaluated as Fdx(x,y)
Fdy = griddedInterpolant({xa, ya}, dZdy_nd.', 'linear', 'none');   % dZ/dy evaluated as Fdy(x,y)

lens_args = {F, Fdx, Fdy, grid_center, x_limits, y_limits};

%% --- Build the bench (same layout as your example) ---
bench = Bench;

% Use 'air' to 'mirror' for a reflective test (no dispersion setup needed).
% For a transmissive lens, swap 'mirror' -> a glass name present in your material set (e.g., 'bk7').
rect_aperture = [0; 0; lens_span_y; lens_span_z];
elem = GeneralLens([0 0 0], rect_aperture, 'surface_lens_corrected', { 'air' 'mirror' }, lens_args{:});
bench.append(elem);

incident_tilt_deg = 0;
incident_dir = [cosd(incident_tilt_deg) 0 -sind(incident_tilt_deg)];

% Screen sized to capture the reflected bundle
screen_width  = max(lens_span_y * 1.25, 64);  % mm (Y)
screen_height = max(lens_span_z * 1.25, 64);  % mm (Z)

% Place a capture screen downstream of the surface
screen_distance = -1000;   % mm along +X
screen = Screen( [ screen_distance 0 1 ], screen_width, screen_height, 512, 512 );
screen.rotate( [ 0 1 0 ], pi );
bench.append( screen );

% Collimated beam aimed normal to the surface
nrays = 500;
source_pos = [ -1200 0 0 ];
incident_dir = [ 1 0 0 ];
aperture = 80;
beam_diam = aperture * 0.95;

rays_in = Rays(nrays, 'collimated', source_pos, incident_dir, beam_diam, 'hexagonal');

fprintf('Tracing rays through surface_lens_corrected ...\n');
rays_out = bench.trace(rays_in);

% Visualize
bench.draw(rays_out, 'lines', 1, 1.5);
axis equal;
grid on;
view(35, 20);
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
camlight('headlight'); camlight('left'); camlight('right');
lighting gouraud;
title('GeneralLens using surface\_lens\_corrected (interpolated surface)', 'Color','w');

figure('Name','surface\_lens screen capture','NumberTitle','Off');
y_coords = linspace(-screen.w/2, screen.w/2, screen.wbins);
z_coords = linspace(-screen.h/2, screen.h/2, screen.hbins);
imagesc(y_coords, z_coords, screen.image);
axis image; colormap hot; colorbar;
set(gca,'YDir','normal');
title('Illumination after surface\_lens\_corrected'); xlabel('Screen Y (mm)'); ylabel('Screen Z (mm)');

if nargout >= 1, varargout{1} = screen; end
if nargout >= 2, varargout{2} = rays_out; end
if nargout >= 3, varargout{3} = bench; end
if nargout >= 4, varargout{4} = elem; end
end
