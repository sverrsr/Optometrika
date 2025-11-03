classdef validation_Blob_simulationTest < matlab.unittest.TestCase
    %VALIDATION_BLOB_SIMULATIONTEST Unit tests for validation_Blob_simulation helper.

    methods (TestClassSetup)
        function addRepositoryToPath(testCase)
            this_file = mfilename('fullpath');
            repo_root = fileparts(fileparts(this_file));
            addpath(repo_root);
            testCase.addTeardown(@() rmpath(repo_root));
        end
    end

    methods (Test)
        function testInitialisesOpticalBench(testCase)
            [X, Y, Z] = validation_Blob_simulationTest.sampleSurface();

            [screen, rays_out, bench, surf, state] = validation_Blob_simulation(X, Y, Z, [], false);

            testCase.verifyClass(screen, 'Screen');
            testCase.verifyClass(rays_out, 'Rays');
            testCase.verifyClass(bench, 'Bench');
            testCase.verifyClass(surf, 'GeneralLens');

            testCase.verifyEqual(state.screen, screen);
            testCase.verifyEqual(state.bench, bench);
            testCase.verifyEqual(state.surf, surf);
            testCase.verifyEqual(state.frame_idx, 1);
            testCase.verifyEqual(size(screen.image), [512, 512]);

            xa = sort(X(1,:));
            ya = sort(Y(:,1));
            [dZdx, dZdy] = gradient(Z, xa, ya);

            testCase.verifyEqual(state.F.Values.', Z, 'AbsTol', 1e-12);
            testCase.verifyEqual(state.Fdx.Values, dZdx, 'AbsTol', 1e-12);
            testCase.verifyEqual(state.Fdy.Values, dZdy, 'AbsTol', 1e-12);
        end

        function testStateReuseUpdatesInterpolants(testCase)
            [X, Y, Z] = validation_Blob_simulationTest.sampleSurface();

            [screen1, ~, bench1, surf1, state1] = validation_Blob_simulation(X, Y, Z, [], false);

            Z2 = Z + 0.1 * sin(X) .* cos(Y);
            [screen2, rays2, bench2, surf2, state2] = validation_Blob_simulation(X, Y, Z2, state1, false);

            testCase.verifyEqual(screen2, screen1);
            testCase.verifyEqual(bench2, bench1);
            testCase.verifyEqual(surf2, surf1);
            testCase.verifyClass(rays2, 'Rays');

            testCase.verifyEqual(state2.frame_idx, 2);
            testCase.verifyEqual(state2.screen, screen2);
            testCase.verifyEqual(state2.bench, bench2);
            testCase.verifyEqual(state2.surf, surf2);
            testCase.verifyEqual(state2.plot_handles, []);
            testCase.verifyEqual(state2.F.Values.', Z2, 'AbsTol', 1e-12);
        end

        function testInvalidGridThrows(testCase)
            x = [0, 0];
            y = [-1, 1];
            [X, Y] = meshgrid(x, y);
            Z = zeros(size(X));

            testCase.verifyError(@() validation_Blob_simulation(X, Y, Z, [], false), ...
                'surface_run:InvalidGrid');
        end
    end

    methods (Static)
        function [X, Y, Z] = sampleSurface()
            x = linspace(-5, 5, 6);
            y = linspace(-4, 4, 5);
            [X, Y] = meshgrid(x, y);
            Z = 0.2 * X.^2 - 0.1 * Y.^2 + 0.05 * X .* Y;
        end
    end

    methods (TestMethodTeardown)
        function closeFigures(~)
            close all force;
        end
    end
end
