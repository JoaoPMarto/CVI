%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Ground Truth %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
% Load the image sequence and ground truth data
%data = dlmread('gt.txt'); %forma antiga de ir buscar os dados
data = readmatrix("gt.txt");
path = 'View_001/frame_'; 
frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];
nFrame = 794; % 794
nInFrame=600;
%vid4D = zeros([576 768 3 nFrame]);
figure; hold on

contador_Area = 0;
contador_AspectRatio = 0;
contador_min_Area = 100000;
contador_min_AspectRatio = 100000;

for k = 1 : nFrame
   % Load the current frame
    fprintf('Iteration %d\n', k);
    str1 = sprintf(str,path,k,'jpg');
    img = imread(str1);
    %vid4D(:,:,:,k)=img;
    imshow(img); % showing image
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
            
            talvez_extremo_area = w*h;
            
            if talvez_extremo_area>contador_Area
                contador_Area = talvez_extremo_area;
                indice_maximo_area = k;
            end

            if talvez_extremo_area<contador_Area
                contador_min_Area = talvez_extremo_area;
                indice_minimo_area = k;
            end

            talvez_extremo_aspectRatio = w/h;

            if talvez_extremo_aspectRatio>contador_AspectRatio
                contador_AspectRatio = talvez_extremo_aspectRatio;
                indice_maximo_aspectRatio = k;
            end

            if talvez_extremo_aspectRatio<contador_AspectRatio
                contador_min_AspectRatio = talvez_extremo_aspectRatio;
                indice_minimo_AspectRatio = k;
            end

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
fprintf('Ground Truth over.')
%% first way to obtain background: low-pass filter

nFrames = 30;
alpha=0.01;
background = get_background(str, path,nFrames,alpha);


%% second way to obtain background: median filter
nFrames = 30;
background_median = median_background(str, path,nFrames);

%% applying the detector algorithm
minArea = 300;
maxArea = 5000;
minAspect = 0.1;
maxAspect = 1.0;
nFrame = 5; % original: 794
nFramesToKeep = 200; % amount of frames for which we keep the past path taken
background_image = background_median;
detector_func(minArea,maxArea,minAspect,maxAspect,nFrame,nFramesToKeep,background_image);

%%
detector_func(minArea,maxArea,minAspect,maxAspect,nFrame,nFramesToKeep,background_image);
