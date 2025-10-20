%% Plots only the surface at s = 1200
x = xMesh;
y = yMesh;
z = surfaceData1200;

% Read data reads data as (y, x, z)

h = surf(x, y, z);

set(h, 'EdgeColor','none')   % hide black grid lines
shading interp;      % optional – smooths the surface
colormap parula;        % optional – sets color map
colorbar;            % optional – adds color bar
zlim([-2 2]); %Adjust z reasonably
xlabel('Y');
ylabel('X');
zlabel('Z');
title('Surface Plot of surfaceData1200');


%% Plotting normals
[Nx, Ny, Nz] = surfnorm(x, y, z);

%% Scattered interpolants
F = griddedInterpolant(x',y',z');
%% Testing interpolants
%{
ans =

  34.095652613805370  34.761379815100540  35.427107016395709
  34.095652613805370  34.761379815100540  35.427107016395709
  34.095652613805370  34.761379815100540  35.427107016395709

yMesh(249:251, 249:251)

ans =

   4.196511600357582   4.196511600357582   4.196511600357582
   3.530784399062441   3.530784399062441   3.530784399062441
   2.865057197767300   2.865057197767300   2.865057197767300

surfaceData1200(249:251, 249:251)

ans =

   0.033496504612738   0.033565322249150   0.033969356407781
   0.037384352343062   0.037892813839338   0.038792520223921
   0.039866245712425   0.040715407358237   0.042036637790670

%}

tiledlayout(1,3)
nexttile
surf(y,x, z)
title('f1')

%Create a grid of query points with a courser mesh size compared to the sample points.
step = 5; % choose how much coarser you want
qx = xMesh(1:step:end, 1:step:end);
qv = yMesh(1:step:end, 1:step:end);
%zCoarse = surfaceData1200(1:step:end, 1:step:end);


[XQ,YQ] = ndgrid(qx,qy);

VQ = F(XQ,YQ);

nexttile
surf(XQ,YQ,VQ(:,:,1))
title('Interpolated f1 course')

nexttile
surf(XQ,YQ,VQ(:,:,1))
title('Interpolated f1 fine')

