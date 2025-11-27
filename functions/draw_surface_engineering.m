function f = draw_surface_engineering(x, y, z, name, save_path)
%DRAW_SURFACE_ENGINEERING Create a technical drawing for a freeform surface.
%
%   f = DRAW_SURFACE_ENGINEERING(x, y, z) builds a multi-view technical
%   drawing for a surface defined on a rectilinear grid. X and Y must be
%   1-D arrays describing the sampling along the two axes and Z is the
%   corresponding height matrix of size [numel(y) x numel(x)].
%
%   f = DRAW_SURFACE_ENGINEERING(..., name, save_path) allows overriding
%   the drawing title and destination path for the exported PDF. If omitted
%   the drawing title defaults to 'surface drawing' and the PDF is saved as
%   'surface_drawing.pdf' in the current directory.
%
%   The drawing includes:
%     * A plan-view false-color map with contour lines and overall
%       dimensions annotated.
%     * Two orthogonal cross-sections through the surface center to expose
%       the sag profile along each axis.
%     * A small table summarizing spans and sag statistics to match the
%       style used by example 8.
%
%   Example:
%       f = draw_surface_engineering(xa, ya, Zi, 'surface lens', ...
%            fullfile(tempdir, 'surface_lens_drawing.pdf'));
%
%   Copyright: Optometrika contributors, 2024
%
arguments
    x (1,:) double {mustBeReal, mustBeFinite}
    y (1,:) double {mustBeReal, mustBeFinite}
    z (:,:) double {mustBeReal}
    name (1,1) string = "surface drawing"
    save_path (1,1) string = "surface_drawing.pdf"
end

if numel(x) < 2 || numel(y) < 2
    error('draw_surface_engineering:InvalidGrid', ...
        'Grid vectors X and Y must each contain at least two samples.');
end

if size(z, 1) ~= numel(y) || size(z, 2) ~= numel(x)
    error('draw_surface_engineering:SizeMismatch', ...
        'Z must be size [numel(Y) x numel(X)].');
end

if any(~isfinite(z(:)))
    error('draw_surface_engineering:InvalidData', ...
        'Z contains NaN or Inf values; provide a finite height map.');
end

% Basic geometry metrics for annotation.
x_span = [min(x), max(x)];
y_span = [min(y), max(y)];
z_span = [min(z(:)), max(z(:))];

center_x = 0.5 * sum(x_span);
center_y = 0.5 * sum(y_span);

% Extract central profiles for orthogonal cross-sections.
[~, cx] = min(abs(x - center_x));
[~, cy] = min(abs(y - center_y));

profile_y = z(:, cx);
profile_x = z(cy, :);

% Create the figure using a tiled layout for clarity.
f = figure('Name', name, 'Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.05 0.05 0.9 0.85]);

tl = tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, char(name), 'FontSize', 16, 'FontWeight', 'bold');

% Plan view with contours
nexttile(tl, 1, [1 1]);
imagesc(x, y, z);
axis equal tight;
set(gca, 'YDir', 'normal');
hold on;
[cset, hcont] = contour(x, y, z, 12, 'k'); %#ok<NASGU>
clabel(cset, hcont, 'Color', 'k', 'FontSize', 8, 'LabelSpacing', 400);
plot(center_x, center_y, 'wo', 'MarkerFaceColor', [0.9 0.1 0.1], ...
    'MarkerSize', 8, 'DisplayName', 'Grid center');
colormap(parula);
colorbar;
xlabel('X (mm)');
ylabel('Y (mm)');
title('Plan view with contour lines');

% Dimension annotations for plan view
line([x_span(1) x_span(2)], y_span(1) * [1 1], 'Color', 'k', 'LineWidth', 1.2);
line(x_span(1) * [1 1], [y_span(1) y_span(2)], 'Color', 'k', 'LineWidth', 1.2);
line([x_span(1) x_span(2)], y_span(2) * [1 1], 'Color', 'k', 'LineWidth', 1.2);
line(x_span(2) * [1 1], [y_span(1) y_span(2)], 'Color', 'k', 'LineWidth', 1.2);
text(center_x, y_span(1) - 0.02 * diff(y_span), ...
    sprintf('X span: %.2f mm', diff(x_span)), 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', 'FontSize', 10, 'FontWeight', 'bold');
text(x_span(1) - 0.02 * diff(x_span), center_y, ...
    sprintf('Y span: %.2f mm', diff(y_span)), 'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Rotation', 90);

% Cross-section along Y (fixed X)
nexttile(tl, 3);
plot(y, profile_y, 'LineWidth', 1.5);
grid on;
xlabel('Y (mm)');
ylabel('Z (mm)');
title(sprintf('Sag along Y (X = %.2f mm)', x(cx)));

% Cross-section along X (fixed Y)
nexttile(tl, 4);
plot(x, profile_x, 'LineWidth', 1.5);
grid on;
xlabel('X (mm)');
ylabel('Z (mm)');
title(sprintf('Sag along X (Y = %.2f mm)', y(cy)));

% Statistics table inspired by example 8 styling
uitable(f, 'Data', {
    'X span (mm)', diff(x_span);
    'Y span (mm)', diff(y_span);
    'Z range (mm)', diff(z_span);
    'Z min (mm)', z_span(1);
    'Z max (mm)', z_span(2);
    'Center sag (mm)', z(cy, cx);
    }, ...
    'ColumnName', {'Metric', 'Value'}, 'Units', 'normalized', ...
    'Position', [0.05 0.02 0.4 0.18], 'FontSize', 10);

% Save to PDF to mirror example 8 output behavior
exportgraphics(f, save_path, 'ContentType', 'vector');
fprintf('Technical drawing saved to %s\n', save_path);

end
