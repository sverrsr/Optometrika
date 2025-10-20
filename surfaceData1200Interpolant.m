function profile = surfaceData1200Interpolant(surfaceData1200, xMesh, yMesh, varargin)
%SURFACEDATA1200INTERPOLANT Build a sag interpolant for the sampled surface.
%   PROFILE = SURFACEDATA1200INTERPOLANT(SURFACEDATA1200, XMESH, YMESH)
%   creates a scattered interpolant that fits the sag samples stored in
%   SURFACEDATA1200 at the grid locations XMESH and YMESH. The function
%   returns a structure that can be passed to SURFACEDATA1200SAGPROFILE via
%   the GeneralLens argument list.
%
%   Optional name-value arguments:
%       'Method'              - Interpolation method used by
%                              scatteredInterpolant (default: 'natural').
%       'ExtrapolationMethod' - Extrapolation method (default: 'none').
%       'ExtrapolationValue'  - Value returned for samples outside the
%                              supported aperture when ExtrapolationMethod
%                              is 'none' (default: NaN).
%       'GradientStep'        - Step (in the lens plane units) used for the
%                              finite-difference normal estimation. If not
%                              provided, the step is inferred from the
%                              input meshes.
%       'SupportPadding'      - Extra margin added to the aperture limits
%                              before treating a query as out-of-support
%                              (default: 0).
%
%   The returned PROFILE structure contains:
%       interpolant      - The scatteredInterpolant object.
%       yLimits, zLimits - Aperture bounds along the lens plane axes.
%       gradientStep     - Step used to evaluate the sag gradients.
%       supportPadding   - Padding used when masking out-of-support samples.
%       extrapolationValue - Value assigned to points outside the support.
%
%   Example
%       dataProfile = surfaceData1200Interpolant(surfaceData1200, xMesh, yMesh);
%       lensArgs = {dataProfile};
%       lens = GeneralLens([0 0 0], 50e-3, 'surfaceData1200SagProfile', ...
%                          {'air','bk7'}, lensArgs{:});
%
%   The returned PROFILE can be cached and re-used across repeated calls to
%   SURFACEDATA1200SAGPROFILE.
%
%   See also scatteredInterpolant, surfaceData1200SagProfile.

% Copyright: 2024 Optometrika contributors

    p = inputParser();
    addParameter(p, 'Method', 'natural', @localIsTextScalar);
    addParameter(p, 'ExtrapolationMethod', 'none', @localIsTextScalar);
    addParameter(p, 'ExtrapolationValue', NaN, @(x) validateattributes(x, {'numeric'}, {'scalar'}));
    addParameter(p, 'GradientStep', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x > 0));
    addParameter(p, 'SupportPadding', 0, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    parse(p, varargin{:});
    opts = p.Results;

    validateattributes(surfaceData1200, {'numeric'}, {'real'});
    validateattributes(xMesh, {'numeric'}, {'real'});
    validateattributes(yMesh, {'numeric'}, {'real'});
    if ~isequal(size(surfaceData1200), size(xMesh), size(yMesh))
        error('surfaceData1200Interpolant:SizeMismatch', ...
            'surfaceData1200, xMesh, and yMesh must have matching sizes.');
    end

    % Build the scattered interpolant.
    F = scatteredInterpolant(xMesh(:), yMesh(:), surfaceData1200(:), ...
        char(opts.Method), char(opts.ExtrapolationMethod));

    % Explicitly set the extrapolation behaviour when supported.
    try %#ok<TRYNC>
        F.ExtrapolationMethod = char(opts.ExtrapolationMethod);
    end
    if ~strcmpi(opts.ExtrapolationMethod, 'none')
        try %#ok<TRYNC>
            F.ExtrapolationValue = opts.ExtrapolationValue;
        end
    end

    % Estimate an appropriate finite-difference step from the sampling grid
    % if the user did not supply one.
    gradientStep = opts.GradientStep;
    if isempty(gradientStep)
        gradientStep = localEstimateStep(xMesh(:), yMesh(:));
    end

    profile = struct(...
        'interpolant', F, ...
        'yLimits', [min(xMesh(:)), max(xMesh(:))], ...
        'zLimits', [min(yMesh(:)), max(yMesh(:))], ...
        'gradientStep', gradientStep, ...
        'supportPadding', opts.SupportPadding, ...
        'extrapolationValue', opts.ExtrapolationValue);
end

function step = localEstimateStep(xCoords, yCoords)
%LOCaLESTIMATESTEP Infer a conservative finite-difference step.
    xCoords = xCoords(:);
    yCoords = yCoords(:);

    % Compute typical spacings along each axis using unique sorted samples.
    dx = localMedianSpacing(xCoords);
    dy = localMedianSpacing(yCoords);

    if isempty(dx) && isempty(dy)
        step = 1;
        return;
    elseif isempty(dx)
        step = dy / 2;
        return;
    elseif isempty(dy)
        step = dx / 2;
        return;
    end

    step = min(dx, dy) / 2;
    if step <= 0 || ~isfinite(step)
        step = max(dx, dy) / 2;
    end

    if step <= 0 || ~isfinite(step)
        step = 1;
    end
end

function spacing = localMedianSpacing(coords)
%LOCALMEDIANSPACING Compute median spacing between unique coordinates.
    coords = sort(coords);
    coords = coords(isfinite(coords));
    coords = unique(coords);
    if numel(coords) < 2
        spacing = [];
        return;
    end
    diffs = diff(coords);
    diffs = diffs(diffs > eps(max(abs(coords))));
    if isempty(diffs)
        spacing = [];
        return;
    end
    spacing = median(diffs);
end

function tf = localIsTextScalar(value)
%LOCALISTEXTSCALAR True for non-empty char or scalar string inputs.
    if ischar(value)
        tf = ~isempty(value);
        return;
    end
    if isa(value, 'string')
        tf = isscalar(value) && all(strlength(value) > 0);
        return;
    end
    tf = false;
end
