function background = median_background(str,path,n)

    
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
end