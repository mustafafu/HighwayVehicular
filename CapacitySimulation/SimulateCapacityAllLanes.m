
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
    mm_seperation = 300; % how many meters between consecutive base stations
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

%sub 6GHz Properties
s6_hBs = 30; % height
s6_coverage = 0.5*(AoI_end-AoI_start) + AoI_start; %put the sub 6Ghz at the center
BSTxPower = 46 ; %dBm
VehTxPower = 24; %dBm
% We are interested in uplink capacity so we will use VehTxPower as power.
TxPower=VehTxPower;
Noise = -173.9 ; %dBm per hertz
fc = 673 ; % Hz
BW = 20 * 1e6; % Hz
NoiseFig = 5; %dB



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
Vb_2 = 100; % blocking vehicle speed (km/h)
Vb_1 = 95;
lambda_vehicle = 0.0343; % 1/(Vc/3.6); % mean space between cars
% 476 cars / 15minutes * (5.7 meters/car) / 65mph / 3 lanes
Vc = Vc/3600; % Vc in m/ms 1000/(3600*1000)
Vb_1 = Vb_1/3600; % Vc in m/ms
Vb_2 = Vb_2/3600; % Vc in m/ms
% height parameters in BV Array
% We can select a uniform RV from 2L vehicle type ??
%ha = 2; % vehicle antenna height (in meters)

%% Initialize mmWave Bs, sub6G Bs, vehicles
Bs_y_pos = widthLane*numLane ; %y axis position of base stations
center_of_interest = AoI_start + (AoI_end - AoI_start)/2; %find the center of interest
%Deploy mmWave Base Stations
mmWaveBsArray = mmWaveBs(AoI_start,AoI_end,mm_seperation,Bs_y_pos,mm_hBs,mm_coverage);
%Deploy sub6Gs Base station
sub6GBs = sub6Bs(AoI_start + (AoI_end - AoI_start)/2,Bs_y_pos,s6_hBs,TxPower,Noise,fc,BW,NoiseFig);
%Create Blocker Vehicles
%y_pos(i)  is the y position of the vehicle on lane i
y_pos = widthLane*[2.5,1.5,0.5];
% Deploy vehicles
veh{3} = BVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vc,y_pos(3));
veh{2} = BVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vb_2,y_pos(2));
veh{1} = BVArray(-AoI_end,AoI_end,lambda_vehicle,mm_coverage,Vb_1,y_pos(1));
%% Simulation Starts here
tic
%just moving the vehicles -Aoi to 0 takes about 100 seconds
simulation_time = (AoI_start - veh{3}(1).car_end)/veh{3}(1).speed;
simulation_length = floor(simulation_time / delta);
%% Creating appropriate arrays to record the simulation data
AssosiationArray = cell(3,1);
AssosiationArray{3} = zeros(simulation_length,length(veh{3}));
AssosiationArray{2} = zeros(simulation_length,length(veh{2}));
AssosiationArray{1} = zeros(simulation_length,length(veh{1}));
DistanceArray = cell(3,1);
DistanceArray{3} = zeros(simulation_length,length(veh{3}));
DistanceArray{2} = zeros(simulation_length,length(veh{2}));
DistanceArray{1} = zeros(simulation_length,length(veh{1}));
s6_CapacityArray = cell(3,1);
s6_CapacityArray{3} = zeros(simulation_length,length(veh{3}));
s6_CapacityArray{2} = zeros(simulation_length,length(veh{2}));
s6_CapacityArray{1} = zeros(simulation_length,length(veh{1}));

%% QoS Capacity requirement
% Because of greedy scheduler, I need these before simulation
qos_capacity_requirements = [1.28,2.56,2.88,10,14,29]*10^6; % per second, per vehicle use case requirements
% All requirements are Mbps
% Cooperative maneuver 1.28
% Cooperative Safety(20VRU) 2.56 (128Kbps * 20)
% Autonomous Navigation 2.88
% Cooperative perception/sensing 10/14/29
% Remote Driving -> Trajectory 1.28
% Remote Driving -> 14-29

%% Array for keeping track of if the QoS requirement of capacity is achieved or not
% 1 is achieved, -1 is not achieved, 0 means the vehicle is not in region of interest at that simulation time step.
isCapacityAchieved = cell(3,length(qos_capacity_requirements));
for CV_lane = 1:numLane
    for serviceIdx = 1:length(qos_capacity_requirements)
        isCapacityAchieved{CV_lane,serviceIdx} = zeros(simulation_length,length(veh{CV_lane}));
    end
end



%% Simulation Running here
tic
now_simulation = 0;
while veh{numLane}(1).car_end < AoI_start
    now_simulation = now_simulation+1;
    %Find which cars are in area of interest
    % there is +- mm_coverage to make sure first and last cars mm_wave
    % coverage from both sides.
    for CV_lane = numLane:-1:1
        Cm_inRange_idx_start = find([veh{CV_lane}.car_end] > AoI_start + mm_coverage,1);
        Cm_inRange_idx_end = find([veh{CV_lane}.car_start] < AoI_end - mm_coverage,1,'last');
        if Cm_inRange_idx_end < Cm_inRange_idx_start
            printf('last and first car inconsistent')
            break;
        end
        % for each communicating vehicle in the region
        [DistanceArray{CV_lane}(now_simulation,:),AssosiationArray{CV_lane}(now_simulation,:),s6_CapacityArray{CV_lane}(now_simulation,:)] = checkConnections(veh,mmWaveBsArray,sub6GBs,Cm_inRange_idx_start,Cm_inRange_idx_end,CV_lane,mm_coverage);
    end
    
    % for vehicles that are ofloaded to the sub6Ghz BS, scheduling the
    % service in a greedy manner, i.e the best channel vehicle is served
    % first then the second best etc,  until all vehicles are served or the
    % duration of simulation time step is depleted
    offloaded_vehicle_idx = cell(1,numLane);
    achieved_capacities = [];
    for CV_lane = 1:numLane
        for serviceIdx = 1:length(qos_capacity_requirements)
            isCapacityAchieved{CV_lane,serviceIdx}(now_simulation,:) = (AssosiationArray{CV_lane}(now_simulation,:) > 0);
        end
        offloaded_vehicle_idx{CV_lane} = find(AssosiationArray{CV_lane}(now_simulation,:) == -1);
        achieved_capacities = [achieved_capacities, s6_CapacityArray{CV_lane}(now_simulation,offloaded_vehicle_idx{CV_lane})];
    end
    vehicles_2b_served = cell2mat(offloaded_vehicle_idx);
    [sorted_capacities, sorted_veh_idx] = sort(achieved_capacities,'descend');
    %starting from most demanding service, if this service is satisfied for
    %all the vehicles remaining services can be satisfied at that time
    %instance
    for serviceIdx = length(qos_capacity_requirements):-1:1
        all_served = 1;
        requirement = qos_capacity_requirements(serviceIdx);
        utilization = 0;
        currently_serving = 1;
        while (utilization < 1) && (currently_serving < length(sorted_veh_idx))
            if (utilization + requirement/sorted_capacities(currently_serving)) < 1
                utilization = utilization + requirement/sorted_capacities(currently_serving);
                currently_serving = currently_serving+1;
            else
                break;
            end
        end
        for veh_idx = 1:length(sorted_veh_idx)
            this_vehicle = sorted_veh_idx(veh_idx);
            vehicle_change_locations = zeros(numLane,1);
            for CV_lane=1:numLane
                vehicle_change_locations(CV_lane)= length(offloaded_vehicle_idx{CV_lane});
            end
            vehicle_change_locations = cumsum(vehicle_change_locations);
            this_vehicle_lane = find(this_vehicle <= vehicle_change_locations,1);
%             disp(this_vehicle)
%             disp(this_vehicle_lane)
%             disp(vehicles_2b_served(this_vehicle))
            if veh_idx <= currently_serving
                isCapacityAchieved{this_vehicle_lane,serviceIdx}(now_simulation,vehicles_2b_served(this_vehicle))=1;
            else
                all_served=0;
                isCapacityAchieved{this_vehicle_lane,serviceIdx}(now_simulation,vehicles_2b_served(this_vehicle))=-1;
            end
        end
    end
    
    
    %Update the positions of the vehicles
    veh{1}.moveCar(delta);
    veh{2}.moveCar(delta);
    veh{3}.moveCar(delta);
end
toc

save_file_string = ['data/distBS_', num2str(mm_seperation), '-heightBS_', num2str(mm_hBs), '-CapacityAssocDistanceAllLanes',AI];
save_file_string = strrep(save_file_string,'.',',')
save(save_file_string, 'AssosiationArray','DistanceArray','s6_CapacityArray','isCapacityAchieved','mmWaveBsArray','veh','delta','qos_capacity_requirements');






