close all
clear all
clc

[x,y] = ndgrid(-1:0.8:1);
z = sin(x.^2 + y.^2) ./ (x.^2 + y.^2);
surf(x,y,z)

F = griddedInterpolant(x,y,z);
hold on

% Interpolated point
xq = -0.569;
yq = -0.569;
zq = F(xq, yq);    % evaluate interpolated z value

% Plot the interpolated point in 3D
plot3(xq, yq, zq, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8)


%%
[X,Y] = meshgrid(-3:3);
V = peaks(X,Y);

figure
surf(X,Y,V)
title('Original Sampling');

G = griddedInterpolant(X',Y',V');

% Interpolated point
xq = -0.569;
yq = -0.569;
zq = F(xq, yq);    % evaluate interpolated z value

%% Trying peaks in toolbox
aperture = 120;  % clear aperture diameter (mm)

% Create a container for optical elements
bench = Bench;

surf = GeneralLens();
surf.r       = [0 0 0];
surf.D = aperture;               % was 6; you set aperture = 120
surf.glass = {'air','mirror'};   % was {'air','glass'}
surf.funch   = @peaks_funch;
surf.funca   = struct('scale', 1, 'yScale', 1, 'zScale', 1, 'offset', 0);

bench.append(surf);

% Place a screen close to the focal region created by the sinusoidal sag.
% Positioning the screen nearer to the mirror (compared with the initial
% demonstration) makes the interference/fringe pattern clearly visible.
screen_distance = -15;




% Match the screen extent to the mirror diameter so that the captured
% heat-map can fill the frame when the mirror aperture is increased.
screen_size = aperture;
screen = Screen( [ screen_distance 0 0 ], screen_size, screen_size, 512, 512 );
screen.rotate( [ 0 1 0 ], pi );
bench.append( screen );


% Generate a collimated bundle of rays aimed at the mirror. The bundle
% diameter is matched to the clear aperture of the surface. Increase both
% the aperture and bundle diameter together to enlarge the mirror footprint.
nrays = 100;
source_pos = [ -150 0 0 ];
incident_dir = [ 1 0 0 ];
bundle_diameter = aperture;
rays_in = Rays( nrays, 'collimated', source_pos, incident_dir, bundle_diameter, 'hexagonal' );
rays_through = bench.trace( rays_in );
bench.draw( rays_through, 'lines', [], 2 );

% Example funch for a peaks-shaped surface x = s(y,z)
function out = peaks_funch(y, z, P, mode)
% y, z column vectors. P holds params like scale, offset, input scaling.
    if nargin < 4, mode = 0; end
    if isempty(P), P = struct('scale',1,'yScale',1,'zScale',1,'offset',0); end

    Y = y / P.yScale;
    Z = z / P.zScale;

    % sag along x
    s = P.scale * peaks(Y, Z) + P.offset;  % peaks(Y,Z) is allowed in MATLAB
                                           % (scalar- or array-valued)
    if mode == 0
        out = s;                           % return sag x = s(y,z)
    else
        % numerical partials for the normal
        h  = 1e-6;
        sY = P.scale * peaks(Y + h, Z) + P.offset;
        sZ = P.scale * peaks(Y, Z + h) + P.offset;
        dsy = (sY - s) / h / P.yScale;     % ∂s/∂y (chain rule for scaling)
        dsz = (sZ - s) / h / P.zScale;     % ∂s/∂z

        n = [ones(size(y)), -dsy, -dsz];   % [1, -sy, -sz]
        n = n ./ sqrt(sum(n.^2,2));        % unit normals
        out = n;
    end
end