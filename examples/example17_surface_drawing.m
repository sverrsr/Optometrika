function example17_surface_drawing()
%EXAMPLE17_SURFACE_DRAWING Create an engineering drawing for a measured surface.
%
% This example mirrors the workflow in examplesurface_lensRun but finishes by
% exporting a technical drawing similar to example 8. The drawing is built
% from the measured height map and includes plan-view contours and
% cross-section plots through the surface center.
%
% Note: the MAT files loaded below must be present on the MATLAB path. They
% are not stored in the repository but should accompany the measured surface
% data delivered by the metrology step.
%
% Copyright: Optometrika contributors, 2024

% Verify that the required data files exist in the current folder.
required_files = {'surfaceData1200.mat', 'surfMesh.mat', 'surfElev_280.00.mat'};
for ii = 1:numel(required_files)
    if ~exist(required_files{ii}, 'file')
        error('example17_surface_drawing:MissingData', ...
            'Required file %s is missing from the working directory.', required_files{ii});
    end
end

% Load surface metadata and elevation grid
load surfaceData1200.mat %#ok<LOAD>
load surfMesh.mat %#ok<LOAD>
load surfElev_280.00.mat %#ok<LOAD>

Z = double(surfElev);
clear surfElev;

% Grid dimensions match examplesurface_lensRun
nx = 256;
ny = 256;
lx = 2 * pi;
ly = 2 * pi;

% Build mesh
[X, Y] = meshgrid((linspace(0, lx, nx)), (linspace(0, ly, ny)));
[xa, ix] = sort(X(1, :));
[ya, iy] = sort(Y(:, 1));

Za = Z(iy, ix);

% Interpolate onto a monotonic grid to remove any irregular spacing
F = griddedInterpolant({xa, ya}, Za.', 'linear', 'none');
Zi = F(X', Y')';

% Create the drawing using the new helper
draw_surface_engineering(xa, ya, Zi, "surface_lens technical drawing", ...
    "surface_lens_drawing.pdf");

fprintf('Engineering drawing saved in surface_lens_drawing.pdf\n');

end
