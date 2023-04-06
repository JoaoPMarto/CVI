% Load the image sequence and ground truth data
data = dlmread('gt.txt');
path = 'View_001/frame_'; 
frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];
nFrame = 795;
vid4D = zeros([576 768 3 nFrame]);

alfa = 0.35;
Bkg = 0;

figure; hold on

for k = 1 : nFrame
   % Load the current frame
    k
    str1 = sprintf(str,path,k,'jpg');
    img = imread(str1);

    %vid4D(:,:,:,k)=img;
    %imshow(img);

    Y = img;
    Bkg = alfa * Y + (1 - alfa)* Bkg;
    imshow(Bkg); drawnow;
    
    hold on;
  
    % Get indices of bounding boxes for the current frame
    frameRows = find(data(:,1) == k);
  
    % Perform tracking for each detection in the current frame
    for i = 1:length(frameRows)
        row = frameRows(i);
        if data(row,8) ~= -1 % if 3D x position is available
            x = data(row,3);
            y = data(row,4);
            w = data(row,5);
            h = data(row,6);
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

