%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Ground Truth %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

prevPositions = [];  % empty matrix for previous positions of the pedestrians
nFramesToKeep = 200;   % Set the number of frames to keep each pedestrian position on screen

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
    fgMask = bwmorph(fgMask, 'clean');
    
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
    end

    % Display output frame 
    imshow(frame);
    % Pause for a short duration between frames (optional)
    %pause(0.001);

end
