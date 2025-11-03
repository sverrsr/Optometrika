% Load the time series
repo_root = fileparts(mfilename('fullpath'));
wave_path = fullfile(repo_root, 'blob', 'wave.h5');
if ~isfile(wave_path)
    error('validation_Blob_simulation_run:MissingWaveData', ...
        ['Expected to find blob/wave.h5 next to validation_Blob_simulation_run.m. ', ...
         'Generate it using blob/runblob.m or copy it to:\n  %s'], wave_path);
end
u = h5read(wave_path, '/u');   % size: [Ny, Nx, Nt]
[Ny, Nx, Nt] = size(u);

% Build the mesh (must match u(:,:,k) indexing)
Lx = 10; Ly = 12;
x = linspace(-Lx/2, Lx/2, Nx);
y = linspace(-Ly/2, Ly/2, Ny);
[X, Y] = meshgrid(x, y);

% Optional visualisation/recording controls
store_images = true;          % set false to skip storing every frame
live_plot    = true;          % set false for headless batch processing

% Trace the first frame (initialises the bench/state)
[screen, ~, ~, ~, state] = validation_Blob_simulation(X, Y, u(:,:,1), [], live_plot);

if store_images
    scr = screen.image;
    screen_stack = zeros([size(scr), Nt], 'like', scr);
    screen_stack(:,:,1) = scr;
end

% Process remaining frames
for k = 2:Nt
    Zk = u(:,:,k);
    [screen, ~, ~, ~, state] = validation_Blob_simulation(X, Y, Zk, state, live_plot);
    if store_images
        screen_stack(:,:,k) = screen.image;
    end
end

% Example: quick playback of the stored screen intensity
if store_images
    figure('Name','Screen intensity over time','NumberTitle','Off');
    him = imagesc(screen_stack(:,:,1)); axis image; colormap hot; colorbar;
    set(gca,'YDir','normal');
    title(sprintf('Frame 1 / %d', Nt)), xlabel('Screen Y bins'), ylabel('Screen Z bins');
    for k = 1:Nt
        set(him, 'CData', screen_stack(:,:,k));
        title(sprintf('Frame %d / %d', k, Nt));
        drawnow;
    end
end
