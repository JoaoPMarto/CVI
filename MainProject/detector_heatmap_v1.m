%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Detector algorithm %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the image sequence
path = 'View_001/frame_'; 
frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];
nFrame = 794; % original: 794
vid4D = zeros([576 768 3 nFrame],'uint8'); % Specify data type


filename = sprintf(str, path, i, 'jpg');


%% final version of the background detector that I settled with

% Load the first n frames and compute the initial background as their average
n = 30;
window_size = [3 3];

% Load all frames into a 4D matrix
frames = zeros(576, 768, 3, n);
for i = 1:n
    filename = sprintf(str, path, i, 'jpg');
    frames(:,:,:,i) = imread(filename);
end

% Apply median filtering to each color channel separately for all frames
filtered = zeros(576, 768, 3);
for channel = 1:3
    filtered_channel = median(frames(:,:,channel,:), 4);
    filtered(:,:,channel) = medfilt2(filtered_channel, window_size, 'symmetric');
end

% Display the filtered output
filtered=uint8(filtered);
imshow(filtered);
background=filtered;

%% Performing the detection

nFrame=794;
% Initialize parameters for pedestrian detection
minArea = 300;
maxArea = 5000;
minAspect = 0.1; 
maxAspect = 1.0;

prevPositions = [];  % empty matrix for previous positions of the pedestrians
nFramesToKeep = 100;   % Set the number of frames to keep each pedestrian position on screen

%%% HM
list_centroids = cell(nFrame,1);

for k = 1 : nFrame
    % print the iteration number
    fprintf('Iteration %d\n', k);
    % Load the current frame
    str1 = sprintf(str,path,k,'jpg');
    img = double(rgb2gray(imread(str1)));
    vid4D(:,:,:,k) = im2uint8(imread(str1)); % Convert to uint8
    frame = imread(str1);
   
    % Update background model using running average of previous frames
    %bgModel = alpha * double(img) + (1 - alpha) * double(bgModel);
    
    % Subtract background model from current frame
    fgMask = abs(img - double(rgb2gray(background))) > 50;

    % Apply morphological operations to remove noise and fill gaps
    fgMask = bwmorph(fgMask, 'clean');
    
    % Detect connected components in foreground mask
    [labels, numLabels] = bwlabel(fgMask);
    props = regionprops(labels, 'Area', 'BoundingBox','Centroid');
    
    % Filter out small and non-rectangular components
    %%%HM
    ped_centroids = zeros(0,2); % initializing the vector with everybody's centroid
    for i = 1:numLabels
        % Get current component properties
        area = props(i).Area;
        bbox = props(i).BoundingBox;
        aspectRatio = bbox(3) / bbox(4);
        %%% HM
        centroid = props(i).Centroid;
        

        % Check if component meets size and shape requirements
        if area >= minArea && area <= maxArea && ...
                aspectRatio >= minAspect && aspectRatio <= maxAspect
            
            %%% HM
            ped_centroids(end+1,:) = centroid; % getting the centroid from each "presumable person"

            % Initialize Kalman filter for this object
            z = [bbox(1)+bbox(3)/2; bbox(2)+bbox(4)/2]; % observation
            x(1:2) = z;    % initialize state estimate with observation
            prevPositions = [prevPositions; x(1:2)];  % Assign that empty matrix for previous pedestrian positions
            
            % Remove old positions that are no longer visible
            if size(prevPositions, 1) > nFramesToKeep
                prevPositions(1,:) = [];
            end

            % Draw bounding box and label on the current frame
            label = sprintf('Pedestrian %d', i);
            frame = insertObjectAnnotation(frame, 'rectangle', bbox, label);
            
            % Plot pedestrian position as black dots
            frame = insertShape(frame, 'FilledCircle', cat(2, prevPositions(:,1), prevPositions(:,2), ones(size(prevPositions,1),1)*2), 'Color','black', 'LineWidth', 1);
        end

        %%% HM
        list_centroids{k} = ped_centroids;
    end

    % Display output frame 
    %imshow(frame);
    %title(sprintf('Detection results for frame %d', k));
    % Pause for a short duration between frames (optional)
    %pause;
    %hold off;
    %drawnow;

end
fprintf('Detector Algorithm over.')

%% performing the heatmap now

% defining size
hm_x = 768;
hm_y = 576;

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
%% displaying the overall heatmap
%figure();
%imagesc(heatmap);
imagesc(bg_overlay(rgb2gray(background), heatmap,0.9995)) % adding the background as overlay
colormap turbo;    
title('Overall heatmap');
colorbar;






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

