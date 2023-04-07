% Load the image sequence and ground truth data
data = dlmread('gt.txt');
path = 'View_001/frame_'; 
frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];
nFrame = 794;
vid4D = zeros([576 768 3 nFrame]);
figure; hold on

for k = 1 : nFrame
   % Load the current frame
    k
    str1 = sprintf(str,path,k,'jpg');
    img = imread(str1);
    vid4D(:,:,:,k)=img;
    imshow(img);
    hold on;
  
    % Get indices of bounding boxes for the current frame
    frameRows = find(data(:,1) == k);
  
    % Perform tracking for each detection in the current frame
    for i = 1:length(frameRows)
        row = frameRows(i);
        if data(row,8) ~= -1 % if 3D x position is available
            x = data(row,3); % Bounding box left
            y = data(row,4); % Bounding box top
            w = data(row,5); % Bounding box width
            h = data(row,6); % Bounding box height
            id = data(row,2); % identity number

            % Draw the bounding box with color red
            color = [1 0 0]; % red
            rectangle('Position', [x, y, w, h], 'EdgeColor',	color, 'LineWidth', 2);

            % Add a text label to the bounding box indicating the identity number
            text(x, y-10, sprintf('ID %d', id), 'Color', color, 'FontSize', 12, 'FontWeight', 'bold');
        end
    end
  
    % Wait for the user to press "Enter" before showing the next frame
    pause;
    hold off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Detector algorithm %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the image sequence
path = 'View_001/frame_'; 
frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];
nFrame = 794;
vid4D = zeros([576 768 3 nFrame],'uint8'); % Specify data type

% Load the first n frames and compute the initial background as their average
n = 30;
background = zeros(576, 768, 3);
alpha = 0.01;
for i = 1:n
    filename = sprintf(str, path, i, 'jpg');
    frame = imread(filename);
    background = background + double(frame)/n;
    % Update the background with a low-pass filter
    %alpha = 0.01;
    background = (1-alpha)*double(background) + alpha*double(frame);
end
background = uint8(background);

% Initialize parameters for pedestrian detection
minArea = 300;
maxArea = 5000;
minAspect = 0.1;
maxAspect = 1.0;

% Initialize output video
outputVideo = VideoWriter('output.avi');
open(outputVideo);

% Initialize kernel for morphological operations
kernel = strel('disk', 5);

for k = 1 : nFrame
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
    fgMask = imclose(fgMask, kernel);
    fgMask = imfill(fgMask, 'holes');
    
    % Detect connected components in foreground mask
    [labels, numLabels] = bwlabel(fgMask);
    props = regionprops(labels, 'Area', 'BoundingBox');
    
    % Filter out small and non-rectangular components
    for i = 1:numLabels
        % Get current component properties
        area = props(i).Area;
        bbox = props(i).BoundingBox;
        aspectRatio = bbox(3) / bbox(4);
        
        % Check if component meets size and shape requirements
        if area >= minArea && area <= maxArea && ...
                aspectRatio >= minAspect && aspectRatio <= maxAspect
            % Draw bounding box around pedestrian and save to output video
            x = bbox(1);
            y = bbox(2);
            w = bbox(3);
            h = bbox(4);           

            % Calculate the centroid of the bounding box
            centroid = [bbox(1)+bbox(3)/2, bbox(2)+bbox(4)/2];

            frame = insertShape(vid4D(:,:,:,k), 'Rectangle', [x y w h], ...
                    'LineWidth', 2, 'Color', 'green');
            frame = insertObjectAnnotation(frame, 'rectangle', [x y w h], ...
                    sprintf('Pedestrian %d', i), 'Color', 'green');
            writeVideo(outputVideo, frame);
        end
    end
end

close(outputVideo);

