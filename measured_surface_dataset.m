function data = measured_surface_dataset()
%MEASURED_SURFACE_DATASET Synthetic measured free-form mirror surface.
%
%   DATA = MEASURED_SURFACE_DATASET() returns a struct describing a sampled
%   mirror profile mimicking measured data from a free-form manufacturing
%   process. The sag values are provided on a regular 501x408 grid spanning
%   +/-50 mm along Y and +/-40 mm along Z. The sag magnitudes cover the
%   range -0.21 .. +0.15 mm and can be directly supplied to MEASURED_SURFACE.
%
%   The dataset is generated procedurally to keep the repository lightweight
%   while still demonstrating how to work with dense measurement grids. The
%   resulting profile exhibits smooth low-order curvature with a localised
%   bump at the centre and gentle astigmatic behaviour, comparable to what a
%   measured mirror might show.
%
%   See also: MEASURED_SURFACE, EXAMPLE17_MEASURED
%
% Copyright: 2024 Optometrika contributors

% Sampling coordinates (millimetres)
y = linspace( -50, 50, 501 );
z = linspace( -40, 40, 408 );
[Y, Z] = ndgrid( y, z );

% Create a smooth free-form sag distribution. The combination of sinusoidal
% components and a Gaussian bump produces a realistic looking form.
base = 0.07 * sin( 2 * pi * Y / 140 ) ...
    + 0.045 * cos( 2 * pi * Z / 90 ) ...
    + 0.025 * exp( -( Y / 28 ).^2 - ( Z / 22 ).^2 ) ...
    - 0.018 * ( Y / 70 );

% Normalise the sag so that it matches the requested magnitude range.
min_sag = min( base( : ) );
max_sag = max( base( : ) );
scaled = ( base - min_sag ) ./ ( max_sag - min_sag );
scaled = scaled * ( 0.15 - ( -0.21 ) ) + ( -0.21 );

% Pack output
data = struct( 'YGrid', y, 'ZGrid', z, 'Sag', scaled );
end
