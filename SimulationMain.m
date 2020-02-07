% clear
% close
% clc

% Shuffle RNG if running in MATLAB, not Octave
if ~exist ('OCTAVE_VERSION', 'builtin')
  rng('shuffle');
end

AI = getenv('SLURM_ARRAY_TASK_ID')
if (isempty(AI))
  warning('Not running on HPC.')  
  AI = '1'; 
  NAI = str2num(AI);
  MAX_ITER = 2; % # of reinitialization and simulation
  NUM_BLOCK = 1000; % # of blockage events to record each iteration
  
  hBs = 3; % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
  numBs = 5; % # of BSs in coverage area
else
  NAI = str2num(AI);
  MAX_ITER = 10; % # of reinitialization and simulation
  NUM_BLOCK = 1000; % # of blockage events to record each iteration
  nRarr = 1:1:5;%1:0.25:4;
  hRarr = [1.5, 2, 3, 4, 5];
  hRidx = floor(mod(NAI,length(nRarr)*length(hRarr))/1/length(nRarr)) + 1;
  nRidx = mod(mod(NAI,length(nRarr)*length(hRarr)), length(nRarr)) + 1;
  hBs = hRarr(hRidx);  % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
  numBs = nRarr(nRidx); % # of BSs in coverage area
  % Set up parallel worker pool
  %parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')))
end

% Input parameters---------------------------------

% Simulation parameters
delta = 1; % simulation granularity in ms

% road parameters
numLane = 2; % number of lanes
whereisCV= 2; % lane on which the communicating vehicle goes
if whereisCV>numLane
  printf('vehicle is not on the road')
  exit
end
widthLane = 3.5;

% vehicle parameters
Vc = 105; % communicating vehicle speed (km/h)
Vb = 100; % blocking vehicle speed (km/h)

lambda_vehicle = 0.036; % 1/(Vb/3.6*1); % mean space between cars
% 476 cars / 15minutes * (5.7 meters/car) / 65mph / 3 lanes
%
% 1/[(105km/hour  -  635 cars/hour/lane   * 5.7 meters/car  ) / (635 ) ]
% ans = 0.0063

mu_vehicle = 0.25; % length of car


Vc = Vc/3600; % Vc in m/ms
Vb = Vb/3600; % Vc in m/ms

% height parameters
% We can select a uniform RV from 2L vehicle type ??
ha = 2; % vehicle antenna height (in meters)

% BS parameters
Rlos = 200; % LoS coverage distance
%--------------------------------------------------


% Other parameters to compute----------------------
% Calculate corresponding arrival and service rates for each blocking lane
% Indicate possibly blocking lanes
blockingLanes = 1:whereisCV - 1; %check_blocking_lanes(hBs,ha,hb,whereisCV);
%-----------------------------------------------------
% These parameters are not required for simulation, they are theoretical pack
% calculation paramaters.
    %% projection of the speed of the car in blocking lanes
    %Vbs = Vc*(blockingLanes-1/2)./(whereisCV-1/2);
    %% calculate lambda and mu for each lane.
    %lambda = fliplr(lambda_vehicle*abs(Vbs-Vb));
    %mu = fliplr(mu_vehicle*abs(Vbs-Vb));
    %-------------------------------------------------------

%% Compute coverage area
temp = sqrt(Rlos^2-(hBs-ha)^2);
temp = sqrt(temp^2-((whereisCV-1/2)*widthLane)^2);
Rcov = temp*2; % Horizontal LoS coverage distance

% Compute inter-BS distance
dBs = Rcov/numBs;
%--------------------------------------------------

% Variables----------------------------------------
probabilityIter = cell(MAX_ITER,1);
durationIter = cell(MAX_ITER,1);
numBlockIter = cell(MAX_ITER,1);

% Initializing vehicle locationss
yLocs=fliplr((blockingLanes-0.5)*widthLane);


tic
for iter = 1:MAX_ITER
    iter
%     if rem(iter,(MAX_ITER/10))==0
%         iter
%         toc
%     end
    blockageCount = 0; % # of blockages that has been observed
    % Initializing the scenario
    locCv = [Rcov/2,(whereisCV-1/2)*widthLane]; % initial location of the communicating vehicle
    % Initializing BS locations
    initialBsLoc = randi(floor(dBs)); % random location for the first BS in the coverage range
    % locBs = initialBsLoc:dBs:(numBs-1)*dBs+initialBsLoc; % initial BS locations
    locBs = initialBsLoc:dBs:min(Rcov, ceil(numBs-1)*dBs+initialBsLoc); % initial BS locations
%     locBsProjected = computeBsProjections(locBs,whereisCV,blockingLanes,locCv);
    % Initializing blocker locations
    [carStartPositions, carLengths, carHeights] = generateBlockers(lambda_vehicle,mu_vehicle,blockingLanes,200); %initial blocker locations
    
    % Initialize blocking state
    locBsProjected = computeBsProjections(locBs,whereisCV,blockingLanes,locCv);

    output = checkConnection(carStartPositions,carLengths,carHeights,locBsProjected,blockingLanes,hBs, whereisCV, ha,locBs,locCv);
    state=output{1};
    isBs_blocked = output{2};
    
    time = 0;
    blockageDuration = 0;
    blockageVec = zeros(1,NUM_BLOCK);
    time_limit = max(max(max(carStartPositions)))/(Vc-Vb);
    while time<=floor(time_limit*0.9)
        time = time + delta;
        locCv(1) = locCv(1) + delta*Vc; % move the communicating vehicle
        
        newBsLoc = locBs(end)+dBs;
        
        if (newBsLoc <= locCv(1)+Rcov/2)
          locBs = [locBs newBsLoc];
        end
        
        if(locBs(1)<locCv(1)-Rcov/2) % if the first BS is out of range, create another BS
            locBs = [locBs(2:end)];
        end
        
        locBsProjected = computeBsProjections(locBs,whereisCV,blockingLanes,locCv);
        
        
        
        carStartPositions = carStartPositions + delta*Vb; % move all blocking vehicles
        pre_state = state;
        output = checkConnection(carStartPositions,carLengths,carHeights,locBsProjected,blockingLanes,hBs, whereisCV, ha,locBs,locCv);
        state=output{1};
        isBs_blocked = output{2};
        
        
        
        if(pre_state == 0)
            blockageDuration = blockageDuration + delta;
            if(state==1) % end of blockage, record duration
                blockageCount = blockageCount + 1;
                blockageVec(blockageCount) = blockageDuration;
                blockageDuration = 0;
            end
        end
    end
    probabilityIter{iter} = sum(blockageVec)/time;
    durationIter{iter} = blockageVec(1:blockageCount);
    numBlockIter{iter} = blockageCount;
end
toc
save_file_string = ['data/numBS_', num2str(numBs), '-heightBS_', num2str(hBs), '-BlockageDurationPercentage-BlockageDurations-',AI];
save_file_string = strrep(save_file_string,'.',',')
save(save_file_string, 'probabilityIter','durationIter', 'numBlockIter');

% mean(probabilityMat)
% mean(mean(durationMat))
% x = reshape(durationMat,1,NUM_BLOCK*MAX_ITER);
% plot(sort(x),[1:1:length(x)]./length(x))
% hold on
% 
% y = exprnd(mean(x),1,length(x));
% plot(sort(y),[1:1:length(y)]./length(y))










