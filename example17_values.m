%% Example 17
close all
clear all
clc
% Call the example17 function to generate the screen, rays, and heatmap
[screen, rays, heatmap, bench, mirror] = example17();

%%
% Create a figure for displaying the processed image
figure()
% Load the image from the screen
A = screen.image;
% Create a disk-shaped filter with a specified radius
K = fspecial("disk",20);   % size, sigma
% Apply the filter to the image using 2D convolution
I = conv2(double(A), K, 'same');
% Display the filtered image with correct aspect ratio
imagesc(I); axis image; set(gca,'YDir','normal')
% Set the colormap to grayscale and add a colorbar
colormap(gray); colorbar
%%
I = imgaussfilt(double(A), 2);   % sigma=2; increase for more blur
imagesc(I); axis image; set(gca,'YDir','normal')
colormap(parula); colorbar
%%
imagesc(A);              % A is your 0/1 matrix
axis image
set(gca,'YDir','normal')
colormap(parula); colorbar



