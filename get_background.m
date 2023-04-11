function background = get_background(str, path,n,alpha)
    % Load the first n frames and compute the initial background as their average
    background = zeros(576, 768, 3);
    for i = 1:n
        filename = sprintf(str, path, i, 'jpg');
        frame = imread(filename);
        background = background + double(frame)/n;
        % Update the background with a low-pass filter
        %alpha = 0.01;
        background = (1-alpha)*double(background) + alpha*double(frame);
    end
    background = uint8(background);
    
    imshow(background) %% vamos ver como ficou o background

end