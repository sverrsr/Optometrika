%example21

%generate arbitrary function surface profiles
startup;

close all;


tic;

for i=1:6
    bench = Bench;
    switch i
        case 1
            % a flat mirror with a step profile
            mirror = SurfaceGeneric([10 00 0],[20 20],@(x,y) 0*x+0*y,{ 'air' 'mirror' } );
            prof = 2/3*[1 1 1; 1 1 1; 0 0 0; 0 0 0]; %step profile (45 deg)
            mirror.profile_set(prof);
            mirror.plot();
            sgtitle('Step Surface 1');
        
        case 2
            % a flat mirror with a step profile
            mirror = SurfaceGeneric([10 00 0],[20 20],@(x,y) 0*x+0*y,{ 'air' 'mirror' } );
            prof = 5*[1 1 1; 1 1 1; 0 0 0; 0 0 0]; %step profile (0.45 deg)
            mirror.profile_set(prof);
            mirror.plot();
            sgtitle('Step Surface 2');
        case 3
            %a complex mirror with a letter "E"
            mirror = SurfaceGeneric([10 0 0],[20 20], @(X,Y) 0.1*X .* exp(-X.^2 - Y.^2),{ 'air' 'mirror' } );
            prof = 5*[0 0 0 0;0 0 0 0; 0 1 1 0; 0 1 1 0; 0 1 0 0; 0 1 0 0; 0 1 1 0; 0 1 1 0;0 1 0 0;0 1 0 0; 0 1 1 0; 0 1 1 0; 0 0 0 0;0 0 0 0]; %letter E
            mirror.profile_set(prof);
            mirror.plot();
            sgtitle('Surface 2 ("E")');
            
        case 4
            % sphere in cartesian coordinates
            r=20;
            fun_sph = @(x,y) r*sqrt(1-x.^2-y.^2);
            mirror = SurfaceGeneric([30 00 0],[40 40],fun_sph,{ 'air' 'mirror' } );
            mirror.plot();
            sgtitle('Sphere');
        case 5
            %sphere in spherical coordinates
             mirror = SurfaceGeneric([30 00 0],[40 40],@(x,y) 0.*x+0*y,{ 'air' 'mirror' } );
             
             %A[az,el] for spherical
             prof = 0*zeros(19);
             prof(10+3,10)=5;
             prof(10,10)=0.5;
             prof(10-3,10)=5;
             
             mirror.profile_set(prof);
             
             mirror.R = 20; % switch to 'spherical'
             mirror.plot();
             mirror.plot_spherical();
          
        case 6
            mirror = SurfaceGeneric([10 0 0],[20 20],@(x,y) 0*x+0*y,{ 'air' 'mirror' });
        
            H = 5;
            n = 80;
            prof = zeros(n,n);
        
            % diagonal step: one side of the diagonal is raised
            [X, Y] = meshgrid(1:n, 1:n);
            prof(Y > X) = H;
        
            mirror.profile_set(prof);
            mirror.plot();
            view(45,25);
            sgtitle('Step Surface (diagonal sharp step)');
             
             
             
             
    end %switch
    
    
    bench.append( mirror );
    screenwf = ScreenGeneric( [ 0 0 0 ], 20, 20, 100, 100,'wf' ); %other options are 'opl' 'wf' 'tilt'
    screenwf.rotate([0 1 0],pi);
    bench.append( screenwf );
    
    % create collimated rays
    nrays = 100;
    rays_in = Rays( nrays, 'collimated', [ 0 0 0 ], [ 1 0 0 ], 16, 'hexagonal','air' );
    toc;
    rays_through = bench.trace( rays_in );    % repeat to get the min spread rays
    bench.draw( rays_through, 'lines' );  % display everything, scale arrow length 2x
    
    figure();
    screenwf.plot3();
end %for
