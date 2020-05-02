%% Simulation Environment Parameters
delta = 3; % simulation granularity in ms
AoI_start = 0; % area of interest start position
AoI_end = 4000; % area of interest end position
%this should be compatible with sub6GHz bs coverage we should get a new
%number

%% Base Station Properties
AI = getenv('SLURM_ARRAY_TASK_ID')
if(isempty(AI))
    AI='3';
    %mmWave BS properties
    mm_hBs = 4; % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
    mm_seperation = 200; % how many meters between consecutive base stations
    % basically this is a new paramater for numBs in coverage region.
    mm_coverage = 200; %meter line of sight LOS path loss tolerable distance
    % num_bs in coverage area is mm_coverage * 2 / mm_seperation
else
    NAI = str2num(AI);
    
    mm_hBs_array = [1.5, 2, 3, 4];
    % num_bs in coverage area is mm_coverage * 2 / mm_seperation
    mm_seperation_array = 75:50:350; % how many meters between consecutive base stations
    
    hBs_index = floor(mod(NAI,length(mm_seperation_array)*length(mm_hBs_array))/1/length(mm_seperation_array)) + 1;
    seperation_index = mod(mod(NAI,length(mm_seperation_array)*length(mm_hBs_array)), length(mm_seperation_array)) + 1;
    
    mm_hBs = mm_hBs_array(hBs_index)
    mm_seperation = mm_seperation_array(seperation_index)
    mm_coverage = 200; %meter line of sight LOS path loss tolerable distance
    % basically this is a new paramater for numBs in coverage region.
end

% Shuffle RNG if running in MATLAB, not Octave
if ~exist ('OCTAVE_VERSION', 'builtin')
    rng(str2num(AI),'twister');
end


%sub 6GHz Properties
s6_hBs = 30; % height
s6_coverage = 0.5*(AoI_end-AoI_start) + AoI_start; %put the sub 6Ghz at the center
BSTxPower = 46 ; %dBm
VehTxPower = 24; %dBm
% We are interested in uplink capacity so we will use VehTxPower as power.
TxPower = BSTxPower; 
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

% GWB bridge data, 19310 vehicles for 3 hours over 7 lane. 
% It is about 919 vehicles per lane per hour
% The speed limit is 45 mph, so in an hour they will cover 72420meters.
% 919 * mean vehicle length (~6.5) = 5983 meters
% the rest of the distance is spacing which is 66436 meters
% this spacing for all vehicles so spacing per vehicle is
% 66436 / 919 = 72.25 meters. The lambda is 1/72.25 = about 0.138
lambda_vehicle = 0.0138406675; 


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
    %Update the positions of the vehicles
    veh{1}.moveCar(delta);
    veh{2}.moveCar(delta);
    veh{3}.moveCar(delta);
end
toc


Parameters = struct('simulation_granularity_ms',delta,...%(ms)
    'Area_of_interest_interval_m',[AoI_start,AoI_end],... (meters)
    'mm_rsu_height_m',mm_hBs,...%(m)
    'mm_seperation_m',mm_seperation,...%(m)
    'mm_coverage_mean_m',mm_coverage,...%(m)
    's6_rsu_height_m',s6_hBs,... %(m)
    's6_coverage_m',s6_coverage,... %(m)
    's6_rsu_pow_dBm',BSTxPower,... %dBm
    's6_Veh_pow_dBm',VehTxPower,... %dBm
    'uplink_downlink_dBm',TxPower,... %dBm
    'Noise_dBm_Hz',Noise,... %dBm
    'fc_MHz',fc,... %MHz
    'BW_Hz',BW,... %Hz
    'Noise_Fig_dB',NoiseFig,... %dB
    'num_lane',numLane,... %num
    'whereisCV',whereisCV,...%num
    'width_lane',widthLane,... %(m)
    'comm_veh_speed_kmh',Vc,...%(kmh)
    'block_veh_speed_kmh_vb1_vb2',[Vb_1,Vb_2],...%(kmh)
    'lambda_vehicle_per_m',lambda_vehicle);%(1/m)



save_file_string = ['data/distBS_', num2str(mm_seperation), '-heightBS_', num2str(mm_hBs), '-CapacityAssocDistanceAllLanes',AI];
save_file_string = strrep(save_file_string,'.',',')
save(save_file_string, 'AssosiationArray','DistanceArray','s6_CapacityArray','mmWaveBsArray','veh','delta','Parameters');






