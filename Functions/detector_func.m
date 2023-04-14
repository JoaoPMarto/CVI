function detector_func(minArea,maxArea,minAspect,maxAspect,nFrame,nFramesToKeep,background)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Detector algorithm %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Load the image sequence
    path = 'View_001/frame_'; 
    frameIdComp = 4;
    str = ['%s%.' num2str(frameIdComp) 'd.%s'];
    vid4D = zeros([576 768 3 nFrame],'uint8'); % Specify data type
    
    % Initialize map to store pedestrian labels
    pedLabels = containers.Map('KeyType', 'double', 'ValueType', 'any');

    prevPositions = [];  % empty matrix for previous positions of the pedestrians
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
        fgMask = abs(img - double(rgb2gray(background))) > 30;
    
        % Apply morphological operations to remove noise and fill gaps
        fgMask = bwmorph(fgMask, 'clean');
        
        % Detect connected components in foreground mask
        [labels, numLabels] = bwlabel(fgMask);
        props = regionprops(labels, 'Area', 'BoundingBox');

        % Initialize counter variable for pedestrian IDs
        pedCounter = 1;
        pedID = 0;

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

                % Search for existing pedestrian labels whose position is close to the current component
                bestDist = Inf;
                bestLabel = 0;

                for id = keys(pedLabels)
                    pos = pedLabels(id{1});
                    dist = norm(x(1:2) - [pos(1),pos(2)]);
                    if dist < bestDist && dist < 50  % use a threshold to determine whether the position is close enough
                        bestDist = dist;
                        bestLabel = id{1};
                    end
                end

                % If an existing label is found, use it; otherwise, assign a new ID
                bestLabel
                if ~isempty(bestLabel) && bestLabel ~= 0
                    pedID = bestLabel;
                else
                    prevPositions = [prevPositions; x(1:2), pedCounter];  % Assign that empty matrix for previous pedestrian positions

                    % Remove old positions that are no longer visible
                    if size(prevPositions, 1) > nFramesToKeep
                        prevPositions(1,:) = [];
                    end
        
                    % Assign a unique ID to this pedestrian
                    pedID = pedCounter;
                    pedCounter = pedCounter + 1;
                end

                % Draw bounding box and label on the current frame
                label = sprintf('Pedestrian %d', pedID);
                frame = insertObjectAnnotation(frame, 'rectangle', bbox, label);
                
                % Plot pedestrian position as black dots
                
                pedLabels(pedID) = z; % Update the dictionary with the new pedestrian id
                frame = insertShape(frame, 'FilledCircle', cat(2, prevPositions(:,1), prevPositions(:,2), ones(size(prevPositions,1),1)*2), 'Color','black', 'LineWidth', 1);
                
            end
        end
    
        % Display output frame 
        imshow(frame);
        % Pause for a short duration between frames (optional)
        %pause;
        hold off;
    
    end
    fprintf('Detector Algorithm over.')
end