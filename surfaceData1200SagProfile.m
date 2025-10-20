function out = surfaceData1200SagProfile(y, z, args, flag)
%SURFACEDATA1200SAGPROFILE Evaluate sag or normals from the interpolated surface.
%   OUT = SURFACEDATA1200SAGPROFILE(Y, Z, ARGS, FLAG) evaluates the sag or
%   normals of the interpolated surface built from the SURFACEDATA1200 data.
%   The first two inputs specify the coordinates in the lens plane. ARGS{1}
%   must be the profile structure returned by SURFACEDATA1200INTERPOLANT.
%   When FLAG == 0 the function returns the sag (X) values. Otherwise it
%   returns the unit surface normals pointing towards +X.
%
%   This function can be used with GeneralLens by passing the profile
%   structure via the constructor's varargin list.
%
%   Example
%       profile = surfaceData1200Interpolant(surfaceData1200, xMesh, yMesh);
%       lens = GeneralLens([0 0 0], 50e-3, 'surfaceData1200SagProfile', ...
%                          {'air','bk7'}, profile);
%
%   See also surfaceData1200Interpolant, GeneralLens.

% Copyright: 2024 Optometrika contributors

    if nargin < 4
        error('surfaceData1200SagProfile:NotEnoughInputs', ...
            'Arguments (y, z, args, flag) are required.');
    end
    if isempty(args)
        error('surfaceData1200SagProfile:MissingProfile', ...
            'The first element of args must contain the interpolant profile.');
    end

    profile = args{1};
    if ~isstruct(profile) || ~isfield(profile, 'interpolant')
        error('surfaceData1200SagProfile:InvalidProfile', ...
            'ARGS{1} must be the structure returned by surfaceData1200Interpolant.');
    end

    yq = y(:);
    zq = z(:);
    sag = profile.interpolant(yq, zq);

    outside = (yq < profile.yLimits(1) - profile.supportPadding) | ...
              (yq > profile.yLimits(2) + profile.supportPadding) | ...
              (zq < profile.zLimits(1) - profile.supportPadding) | ...
              (zq > profile.zLimits(2) + profile.supportPadding);
    sag(outside) = profile.extrapolationValue;

    if flag == 0
        out = reshape(sag, size(y));
        return;
    end

    if ~isfield(profile, 'gradientStep') || isempty(profile.gradientStep) || ...
            ~isfinite(profile.gradientStep) || profile.gradientStep <= 0
        error('surfaceData1200SagProfile:InvalidGradientStep', ...
            'A positive finite gradientStep must be defined in the profile structure.');
    end

    h = profile.gradientStep;
    sag_y_plus  = profile.interpolant(yq + h, zq);
    sag_y_minus = profile.interpolant(yq - h, zq);
    sag_z_plus  = profile.interpolant(yq, zq + h);
    sag_z_minus = profile.interpolant(yq, zq - h);

    dSdy = (sag_y_plus - sag_y_minus) ./ (2 * h);
    dSdz = (sag_z_plus - sag_z_minus) ./ (2 * h);

    normals = [ones(numel(yq), 1), -dSdy(:), -dSdz(:)];
    mags = sqrt(sum(normals.^2, 2));

    invalid = outside | ~isfinite(mags) | mags < eps;
    valid = ~invalid;

    if any(valid)
        normals(valid, :) = bsxfun(@rdivide, normals(valid, :), mags(valid)); %#ok<BSFXFM>
    end
    normals(~valid, :) = NaN;

    out = normals;
end
