function display_heatmap_func(hm_y, hm_x, nFrame, list_centroids, background)
% initializing
heatmap = zeros(hm_y, hm_x);

% Gaussian kernel's s.d.
sigma = 20;


fig = figure();
% looping through all frames
for k = 1:nFrame
    
    imagem = get_frame(k);
    
    points = list_centroids{k};
    
    heatmap_frame = actual_working_heatmap(points, imagem,sigma);
    
    % Add the heatmap for this frame to the overall heatmap
    heatmap = heatmap + heatmap_frame;
    
    % Display the heatmap for this frame
    clf(fig)
    imagesc(bg_overlay(rgb2gray(imagem), heatmap_frame,0.9995)) % if you want the plot of the dynamic heatmap
    %imagesc(bg_overlay(rgb2gray(imagem), heatmap / max(max(heatmap)),0.9995)) % if you want the plot of the progressive construction of the static heatmap
    colormap turbo;
    title(sprintf('Heatmap for frame %d', k));
    colorbar;
    drawnow;
    
end    
% Normalize the heatmap to the range [0,1]
heatmap = heatmap / max(max(heatmap));
% displaying the overall heatmap
%figure();
%imagesc(heatmap);
imagesc(bg_overlay(rgb2gray(background), heatmap,0.9995)) % adding the background as overlay
colormap turbo;    
title('Overall heatmap');
colorbar;
end

%%

function blendedImage = bg_overlay(background, heatmap,alpha)
% alpha value meaning:
% if you want overlay: 0.99; if you only want heatmap: 1

% Create a new image by blending the background image and the heatmap
blendedImage = (1-alpha)*double(background) + alpha*double(heatmap);

% Normalize the blended image to the range [0, 255]
blendedImage = uint8(blendedImage / max(blendedImage(:)) * 255);

end



function density = actual_working_heatmap(points, frame,sigma_value)
x = points(:,1);
y = points(:,2);

% Define the size of the grid (you can adjust this as needed)
grid_size = 1;
num_rows = ceil(size(frame,1) / grid_size);
num_cols = ceil(size(frame,2) / grid_size);

% Convert x and y coordinates to indices of the grid
x_idx = ceil(x / grid_size);
y_idx = ceil(y / grid_size);

% Create a 2D histogram of the indices
histogram = accumarray([y_idx x_idx], 1, [num_rows num_cols]);

% Create a Gaussian kernel with sigma
sigma = sigma_value; % adjust as needed
kernel_size = 2 * ceil(3*sigma) + 1;
kernel = fspecial('gaussian', kernel_size, sigma);

% Convolve the histogram with the kernel
density = conv2(histogram, kernel, 'same');

% Normalize the density
density = density / max(density(:));

% Display the density map
%figure();
%alpha = 0.999;
%bg_overlay(rgb2gray(frame), density,alpha);
%colormap(jet);

%imshow(density);
%colormap(jet);
%colorbar;

%hold on;
%scatter(points(:, 1), points(:, 2), 'white');
end


function frame = get_frame(i)
    path = 'View_001/frame_'; 
    frameIdComp = 4;
    str = ['%s%.' num2str(frameIdComp) 'd.%s'];
    filename = sprintf(str, path, i, 'jpg');
    frame = imread(filename);
end
