function [iPPG_time30, iPPG_signal30filt, iPR_time, iPR, iBR_time, iBR]...
    = ippg_luv_skindetect_cwt(file, mode, display)
% INPUTS: 
%	file: source folder path (.png images) or video path/filename.
%	mode: 'video' or 'folder'. If 'folder' is specified, images must follow a %04d template that starts from 0, i.e. '0000.png', '0001.png'...
%   display: 0 = no display, 1 = display signals only, 2 = display signals and face tracking.
%
% OUTPUTS:
%   iPPG_time30, iPPG_signal30filt: iPPG signal and time vectors (u* channel filtered using its CWT representation).
%   iPR_time, iPR: instantaneous (beat-to-beat) pulse rate.
%   iBR_time, iBR: instantaneous (beat-to-beat) breathing rate.
%
% Reference: Frédéric Bousefsaf, Alain Pruski, Choubeila Maaoui, Continuous wavelet filtering on webcam photoplethysmographic signals to remotely assess the instantaneous heart rate, Biomedical Signal Processing and Control, vol. 8, n° 6, pp. 568–574 (2013)


%% PREPARE IMAGES / VIDEO LOADING
if (strcmp(mode, 'video'))
    vidObj = VideoReader(file);
    length_vid = vidObj.NumberOfFrames;
    
    iPPG_time = zeros(1, length_vid);
    iPPG_signal = zeros(1, length_vid);
    
    % need to recreate vidObj because we called NumberOfFrames property
    vidObj = VideoReader(file);
    
else
    if (exist([file '\times.txt']))
        iPPG_time = dlmread([file '\times.txt'],' ',1,0)/1000;
        
    % construct time variable if not already existing (30 fps by default)
    else
        listing = dir(file);
        iPPG_time = 0:1/30:(length(listing)-2)/30 - 1/30;
    end
    
    iPPG_signal = zeros(1, length(iPPG_time));
end

%% INIT FACE DETECTION AND TRACKING
faceDetector = vision.CascadeObjectDetector();
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
numPts = 0;


for i=1:length(iPPG_time)
    %% LOAD IMAGES
    if (strcmp(mode, 'video'))
        img = readFrame(vidObj);
    else
        image_name = sprintf('%04d.png',i-1);
        img = imread([file '\' image_name]);
    end
    
    img = double(img)/255;
    img_gray = rgb2gray(img);
    
    %% FACE DETECTION AND TRACKING
    if numPts < 10
        % Detection mode
        bbox = faceDetector.step(img_gray);
        
        if ~isempty(bbox)
            % Find corner points inside the detected region.
            points = detectMinEigenFeatures(img_gray, 'ROI', bbox(1, :));
            
            % Re-initialize the point tracker.
            xyPoints = points.Location;
            numPts = size(xyPoints,1);
            release(pointTracker);
            initialize(pointTracker, xyPoints, img_gray);
            
            oldPoints = xyPoints;
            
            bboxPoints = bbox2points(bbox(1, :));
            bboxPolygon = reshape(bboxPoints', 1, []);
            
            if (display==2)
                figure(1)
                subplot(1,2,1)
                
                % Display a bounding box around the detected face
                img_display = insertShape(img, 'Polygon', bboxPolygon, 'LineWidth', 3);
                
                % Display detected corners
                img_display = insertMarker(img_display, xyPoints, '+', 'Color', 'white');
                
                imshow(img_display)
            end
        end
        
    else
        % Tracking mode
        [xyPoints, isFound] = step(pointTracker, img_gray);
        visiblePoints = xyPoints(isFound, :);
        oldInliers = oldPoints(isFound, :);
        
        numPts = size(visiblePoints, 1);
        
        if numPts >= 10
            % Estimate the geometric transformation between the old points and the new points.
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
            
            % Apply the transformation to the bounding box.
            bboxPoints = transformPointsForward(xform, bboxPoints);
            bboxPolygon = reshape(bboxPoints', 1, []);
            
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
            
            bbox = round([bboxPolygon(1) bboxPolygon(2) bboxPolygon(3)-bboxPolygon(1) bboxPolygon(6)-bboxPolygon(2)]);
            
            
            if (display==2)
                figure(1)
                subplot(1,2,1)
                
                % Display a bounding box around the face being tracked
                img_display = insertShape(img, 'Polygon', bboxPolygon, 'LineWidth', 3);
                
                % Display tracked points
                img_display = insertMarker(img_display, visiblePoints, '+', 'Color', 'white');
                
                imshow(img_display)
            end
        end
    end
    
    img_roi = img(bbox(2):bbox(2)+bbox(4), bbox(1):bbox(1)+bbox(3), :);
    
    
    %% SKIN DETECTION
    img_roi_ycbcr = rgb2ycbcr(img_roi);
    %         img_roi_ycbcr = imgaussfilt(img_roi_ycbcr, 3);  % optional
    
    img_roi_thresh_Y = img_roi_ycbcr(:,:,1) > 80/255;
    img_roi_thresh_Cb = img_roi_ycbcr(:,:,2) > 77/255 & img_roi_ycbcr(:,:,2) < 127/255;
    img_roi_thresh_Cr = img_roi_ycbcr(:,:,3) > 133/255 & img_roi_ycbcr(:,:,3) < 173/255;
    
    img_roi_skin = img_roi_thresh_Y & img_roi_thresh_Cb & img_roi_thresh_Cr;
    
    
    %% COLORSPACE CONVERSION
    img_roi_luv = rgb2xyz(img_roi);
    cform = makecform('xyz2uvl');
    img_roi_luv = applycform(img_roi_luv, cform);
    
    if (display==2)
        subplot(1,2,2)
        imshow(img_roi_skin)
    end
    
    
    %% IMAGE -> SIGNAL
    iPPG_signal(i) = sum(sum(img_roi_luv(:,:,1).*img_roi_skin))/sum(sum(img_roi_skin));
    
    
    %% DISPLAY INFORMATIONS (STATE OF ADVANCEMENT)
    if (mod(i, 10)==0)
        disp([int2str(i) ' over ' int2str(length(iPPG_time)) ' frames have been processed'])
    end
end


%% FILTERING USING CWT

% resample to 30 Hz
iPPG_time30 = iPPG_time(1):1/30:iPPG_time(end);
iPPG_signal30 = interp1(iPPG_time, iPPG_signal, iPPG_time30, 'pchip');

% cwt filtering
wavelet_type = 'amor';
wt = cwt(iPPG_signal30, wavelet_type, 30, 'VoicesPerOctave', 32, 'FrequencyLimits', [0.667 4]);    % 0.65 - 3 Hz in the original paper
wt_energy = sum(abs(wt'));
wt_filt = wt .* repmat(wt_energy, size(wt, 2), 1)';

iPPG_signal30filt = icwt(wt_filt, 'amor');


%% INSTANTANEOUS (BEAT-TO-BEAT) PULSE RATE
fs256 = 256;
iPPG_time256 = iPPG_time(1):1/fs256:iPPG_time(end);
iPPG_signal256filt = interp1(iPPG_time30, iPPG_signal30filt, iPPG_time256, 'spline');

[pks_iPPG, locs_iPPG] = findpeaks(iPPG_signal256filt*-1, 'MinPeakHeight', 0, 'MinPeakDistance', 256/4);
pks_iPPG = pks_iPPG * -1;

iPR_time = iPPG_time256(locs_iPPG);
iPR = gradient(iPPG_time256(locs_iPPG));
iPR = 60./iPR;


%% INSTANTANEOUS (BEAT-TO-BEAT) BREATHING RATE
iPR_time30 = iPR_time(1):1/30:iPR_time(end);
iPR30 = interp1(iPR_time, iPR, iPR_time30, 'pchip');    % linear in the article

wt = cwt(iPR30, wavelet_type, 30, 'VoicesPerOctave', 32, 'FrequencyLimits', [0.15 0.4]);
wt_energy = sum(abs(wt'));
wt_filt = wt .* repmat(wt_energy, size(wt, 2), 1)';

iPR30filt = icwt(wt_filt, 'amor');

[pks_iPR, locs_iPR] = findpeaks(iPR30filt, 'MinPeakHeight', 0, 'MinPeakDistance', 30/0.4);
pks_iPR = pks_iPR * -1;

iBR_time = iPR_time30(locs_iPR);
iBR = gradient(iPR_time30(locs_iPR));
iBR = 60./iBR;



%% DISPLAY RESULTS
if (display >= 1)
    figure(2)
    subplot(3,1,1)
    plot(iPPG_time, (iPPG_signal-mean(iPPG_signal))/std(iPPG_signal), iPPG_time256, iPPG_signal256filt/std(iPPG_signal256filt), iPPG_time256(locs_iPPG), iPPG_signal256filt(locs_iPPG)/std(iPPG_signal256filt), '*r')
    legend('raw', 'filtered', 'min')
    title('iPPG signals')
    
    subplot(3,1,2)
    stairs(iPR_time, iPR)
    title('beat-to-beat PR')
    
    subplot(3,1,3)
    stairs(iBR_time, iBR)
    title('beat-to-beat BR')
end


end