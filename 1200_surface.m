function x = sinusoidal_surface( y, z, args, flag )
%SINUSOIDAL_SURFACE General surface function for a bi-axial sinusoidal profile.
%
%   x = SINUSOIDAL_SURFACE( y, z, args, flag ) implements the interface
%   expected by the GeneralLens class. The surface height is defined as a
%   sum of sine waves along the Y and Z directions. The args cell array must
%   contain the amplitudes and spatial periods for each axis:
%       args{1} - amplitude along Y (in the same length units as the bench)
%       args{2} - period along Y
%       args{3} - (optional) amplitude along Z. If omitted, args{1} is used.
%       args{4} - (optional) period along Z. If omitted, args{2} is used.
%
%   When flag == 0 the function returns the surface sag (X coordinate)
%   evaluated at the supplied Y and Z coordinates. Otherwise it returns a
%   matrix of surface normals pointing in the +X direction.
%
%   This surface function is used by example17 to create a reflective
%   sinusoidal free-form surface for FSGD demonstrations.
%
% Copyright: 2024 Optometrika contributors


if flag == 0
    ;
else
    c = 1 ./ sqrt( 1 + ( 2 * pi * args{1} / args{2} .* sin( 2 * pi / args{2} * r ) ).^2 );
    s = sqrt( 1 - c.^2 );
    th = atan2( z, y );
    x = -sign( args{ 1 } ) * [ -sign( args{ 1 } ) * c, s .* cos( th ), s .* sin( th ) ];
end
end
