
% Shuffle RNG if running in MATLAB, not Octave
if ~exist ('OCTAVE_VERSION', 'builtin')
  rng('shuffle');
end

%% Simulation Environment Parameters
delta = 3; % simulation granularity in ms
AoI_start = 0; % area of interest start position
AoI_end = 4000; % area of interest end position
%this should be compatible with sub6GHz bs coverage we should get a new
%number

%% Base Station Properties
AI = getenv('SLURM_ARRAY_TASK_ID')
if(isempty(AI))
  AI='NoAi';
  %mmWave BS properties
  mm_hBs = 2; % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
  mm_seperation = 200; % how many meters between consecutive base stations 
  % basically this is a new paramater for numBs in coverage region.
  mm_coverage = 200; %meter line of sight LOS path loss tolerable distance
  % num_bs in coverage area is mm_coverage * 2 / mm_seperation
else
  NAI = str2num(AI);
  
  mm_hBs_array = [1.5, 2, 3, 4];
  % num_bs in coverage area is mm_coverage * 2 / mm_seperation
  mm_seperation_array = 75:25:350; % how many meters between consecutive base stations 
  
  hBs_index = floor(mod(NAI,length(mm_seperation_array)*length(mm_hBs_array))/1/length(mm_seperation_array)) + 1;
  seperation_index = mod(mod(NAI,length(mm_seperation_array)*length(mm_hBs_array)), length(mm_seperation_array)) + 1;
  
  mm_hBs = mm_hBs_array(hBs_index)
  mm_seperation = mm_seperation_array(seperation_index)
  mm_coverage = 200; %meter line of sight LOS path loss tolerable distance
  % basically this is a new paramater for numBs in coverage region.
end 

%sub 6GHz BS Properties
s6_hBs = 20;
s6_coverage = 0.5*(AoI_end-AoI_start) + AoI_start; %put the sub 6Ghz at the center

%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
  printf('vehicle is not on the road')
  exit
end
widthLane = 3.5; % how wide each lane is?

%% vehicle parameters
Vc = 105; % communicating vehicle speed (km/h)
Vb = 100; % blocking vehicle speed (km/h)
lambda_vehicle = 0.0346; % 1/(Vb/3.6*2); % mean space between cars
% 476 cars / 15minutes * (5.7 meters/car) / 65mph / 3 lanes
mu_vehicle = 0.25; % avg length of car
Vc = Vc/3600; % Vc in m/ms 1000/(3600*1000)
Vb = Vb/3600; % Vc in m/ms
% height parameters
% We can select a uniform RV from 2L vehicle type ??
ha = 2; % vehicle antenna height (in meters)

%% Initialize mmWave Bs, sub6G Bs, vehicles
Bs_y_pos = widthLane*numLane ; %y axis position of base stations
center_of_interest = AoI_start + (AoI_end - AoI_start)/2; %find the center of interest
%Deploy mmWave Base Stations
mmWaveBsArray = mmWaveBs(AoI_start,AoI_end,mm_seperation,Bs_y_pos,mm_hBs,mm_coverage);
%Deploy sub6Gs Base station
sub6GBs = sub6Bs(AoI_start + (AoI_end - AoI_start)/2,Bs_y_pos,s6_hBs);
%Create Blocker Vehicles
%y_pos(i)  is the y position of the vehicle on lane i 
y_pos = widthLane*[2.5,1.5,0.5];
% Deploy blocking vehicles
Bl_veh{2} = BVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vb,y_pos(2));
Bl_veh{1} = BVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vb,y_pos(1));
%Create Communicating Vehicle
Cm_veh = CVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vc,y_pos(3));

%% Simulation Starts here
tic
%just moving the vehicles -Aoi to 0 takes about 100 seconds
simulation_time = (AoI_start - Cm_veh(1).car_end)/Cm_veh(1).speed;
simulation_length = floor(simulation_time / delta);
AssosiationArray = zeros(simulation_length,length(Cm_veh));
DistanceArray = zeros(simulation_length,length(Cm_veh));
now_simulation = 0;
while Cm_veh(1).car_end < AoI_start
    now_simulation = now_simulation+1;
    %Find which cars are in area of interest
    % there is +- mm_coverage to make sure first and last cars mm_wave
    % coverage from both sides. 
    Cm_inRange_idx_start = find([Cm_veh.car_end] > AoI_start + mm_coverage,1);
    Cm_inRange_idx_end = find([Cm_veh.car_start] < AoI_end - mm_coverage,1,'last');
    if Cm_inRange_idx_end < Cm_inRange_idx_start
        printf('last and first car inconsistent')
        break;
    end
    % for each communicating vehicle in the region
    for Cm_idx = Cm_inRange_idx_start : Cm_inRange_idx_end
        %antenna position of communicating vehicle
        Cm_veh_pos = Cm_veh(Cm_idx).x_pos; 
        %LOS coverage range for this antenna
        cov_range_start = Cm_veh_pos-mm_coverage;
        cov_range_end = Cm_veh_pos+mm_coverage;
        % mmWave Base Stations in this coverage area
        inRange_Bs = mmWaveBsArray(mmWaveBsArray.find_Bs_in_range(cov_range_start,cov_range_end));
        Cv_mmBs_distance = Cm_veh(Cm_idx).computeBsDistance(inRange_Bs);
        Cv_s6Bs_distance = -1;
        for Bs_idx = length(inRange_Bs):-1:1
            possibleBlockers = [Bl_veh{2}(Bl_veh{2}.find_Bv_in_range(inRange_Bs(Bs_idx),Cm_veh(Cm_idx))),...
                                Bl_veh{1}(Bl_veh{1}.find_Bv_in_range(inRange_Bs(Bs_idx),Cm_veh(Cm_idx)))];
            if ~isempty(possibleBlockers)
                Cv_mmBs_distance(Bs_idx) = -1;
                Cv_s6Bs_distance = Cm_veh(Cm_idx).computeBsDistance(sub6GBs);
            end
        end
        [min_dist,min_idx]=min(Cv_mmBs_distance([Cv_mmBs_distance > 0]));
        if ~isempty(min_dist)
           DistanceArray(now_simulation,Cm_idx) = min_dist;
           AssosiationArray(now_simulation,Cm_idx) = mmWaveBsArray.find_idx_in_main_array(inRange_Bs(min_idx));
        else
            DistanceArray(now_simulation,Cm_idx) = Cv_s6Bs_distance;
            AssosiationArray(now_simulation,Cm_idx) = -1; %-1 indicated it is associated with the sub 6Ghz Base station
        end
    end
    
    %Update the positions of the vehicles
    Bl_veh{1}.moveCar(delta);
    Bl_veh{2}.moveCar(delta);
    Cm_veh.moveCar(delta);

end
toc

save_file_string = ['data/distBS_', num2str(mm_seperation), '-heightBS_', num2str(mm_hBs), '-AssocDistanceArrays',AI];
save_file_string = strrep(save_file_string,'.',',')
save(save_file_string, 'AssosiationArray','DistanceArray','mmWaveBsArray','Cm_veh','Bl_veh','delta');
