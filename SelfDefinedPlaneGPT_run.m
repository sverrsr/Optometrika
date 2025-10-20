function example18()
%EXAMPLE18 Demonstrate a GeneralLens surface defined from sampled sag data.
%
%   This example constructs a reflective free-form surface whose sag is
%   specified on a rectangular grid. The surface is fed to the SelfDefinedPlane
%   helper which exposes the interface expected by the GeneralLens class.
%
%   Run example18 to visualise the mirror using Bench.draw. The example does
%   not launch a ray trace to keep execution time short.
%
%   Copyright: 2024 Optometrika contributors

[yGrid, zGrid] = ndgrid( -8 : 0.5 : 8 );
R = sqrt( yGrid.^2 + zGrid.^2 ) + eps;
sag = sin( R ) ./ R;

mirrorDataY = yGrid( :, 1 );
mirrorDataZ = zGrid( 1, : );

bench = Bench;
mirror = GeneralLens( [ 0 0 0 ], 20, 'SelfDefinedPlane', { 'air' 'mirror' }, ...
    mirrorDataY, mirrorDataZ, sag );
bench.append( mirror );

figure;
bench.draw( 20, 'lines', [], 2 );
title( 'GeneralLens with self-defined sag surface' );
axis vis3d;

end