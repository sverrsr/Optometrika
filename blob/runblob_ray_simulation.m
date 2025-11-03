%RUNBLOB_RAY_SIMULATION Animate ray tracing through the dynamic blob surface.
%   This script combines the surface playback from runblob.m with the optical
%   bench defined in validation_GaussianBlob.m.  It visualises both the evolving
%   surface sag and the irradiance captured on the downstream screen as the
%   time-series progresses.

% Locate resources relative to this script
script_dir = fileparts(mfilename('fullpath'));
repo_root  = fileparts(script_dir);
cleanup_path = addTemporaryPath(repo_root);

% Load the simulated wavefront (Ny x Nx x Nt)
wave_path = fullfile(script_dir, 'wave.h5');
if ~isfile(wave_path)
    error('runblob_ray_simulation:MissingWaveData', ...
        ['Expected to find blob/wave.h5 next to runblob_ray_simulation.m. ', ...
         'Generate it using blob/runblob.m or copy it to:\n  %s'], wave_path);
end
u = h5read(wave_path, '/u');
[Ny, Nx, Nt] = size(u);

% Build the mesh that corresponds to u(:,:,k)
Lx = 10; Ly = 12;
x = linspace(-Lx/2, Lx/2, Nx);
y = linspace(-Ly/2, Ly/2, Ny);
[X, Y] = meshgrid(x, y);

% Visualise the evolving surface sag (mirrors runblob.m)
A = max(abs(u(:)));
if A == 0
    A = 1;  % avoid degenerate z-limits for a perfectly flat surface
end
surf_fig = figure('Name','Blob surface sag','NumberTitle','Off');
hSurf = surf(X, Y, u(:,:,1));
shading interp;
colormap(surf_fig, 'parula');
axis tight;
axis([min(x) max(x) min(y) max(y) -A A]);
xlabel('x (mm)'); ylabel('y (mm)'); zlabel('Sag (mm)');
title(sprintf('Surface sag (frame %d / %d)', 1, Nt));

% Trace rays for each frame, reusing the helper that manages the bench
[screen, rays_out, bench, surf_obj, state] = validation_Blob_simulation(X, Y, u(:,:,1), [], true);

% Optionally, inspect the optical layout throughout the animation
bench_fig = figure('Name','Optical bench with blob surface','NumberTitle','Off');
bench.draw(rays_out, 'lines', 1, 1.5, 0);
title('Optical bench with blob surface');

% Step through the remaining frames
for k = 2:Nt
    Zk = u(:,:,k);

    % Update the surface visualisation
    set(hSurf, 'ZData', Zk);
    title(sprintf('Surface sag (frame %d / %d)', k, Nt));

    % Re-trace rays through the updated surface and refresh the screen plot
    [screen, rays_out, bench, surf_obj, state] = validation_Blob_simulation(X, Y, Zk, state, true);

    % Refresh the bench view if the figure is still open
    if isgraphics(bench_fig)
        figure(bench_fig); clf(bench_fig);
        bench.draw(rays_out, 'lines', 1, 1.5, 0);
        title('Optical bench with blob surface');
    end

    drawnow limitrate;
end

% Keep variables in workspace for further analysis if desired
assignin('base', 'runblob_ray_screen', screen);
assignin('base', 'runblob_ray_state', state);
assignin('base', 'runblob_ray_bench', bench);
assignin('base', 'runblob_ray_surface', surf_obj);

clear cleanup_path;  % trigger path cleanup

function cleaner = addTemporaryPath(repo_root)
%ADDTEMPORARYPATH Ensure the repository root is on the path for the duration
%of this script, removing it automatically upon completion.

added = addpath(repo_root);
cleaner = onCleanup(@() rmpath(added));
