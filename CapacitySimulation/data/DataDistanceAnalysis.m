%% Base Station Parameters
height = [1.5,2,3,4];
dist = 75:25:350;
%% sub 6 GHz BS paramaters
TxPower = 46 ; %dBm
Noise = -173.9 ; %dBm per hertz
fc = 700 ; % Hz
BW = 20 * 1e6; % Hz
sub6GHz_height = 20; %meters



%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

%% Data Parsing
achieved_capacity = cell(length(height),length(height));


for jj = 1:length(height)
    for dd = 1:length(dist)
        get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        offloaded_distances= cell(length(files),numLane);
        capacities_t = cell(length(files),numLane);
        achv_capacity= cell(length(files),1);
        for ii=1:length(files)
            load(files(ii).name)
            total_duration = size(AssosiationArray{3},1);
            achv_capacity{ii} = cell(total_duration,1);
            lane3 = cell(total_duration,1);
            lane2 = cell(total_duration,1);
            for time_idx = 1:size(lane3,1)
                %for lane 3
                interest_vehicles = find(AssosiationArray{3}(time_idx,:) == -1);
                lane3{time_idx} = zeros(1,length(interest_vehicles));
                for veh_idx = 1:length(interest_vehicles)
                    lane3{time_idx}(veh_idx) = calculate_capacity(DistanceArray{3}(time_idx,interest_vehicles(veh_idx)), fc, sub6GHz_height, veh{3}(interest_vehicles(veh_idx)).car_height, TxPower, Noise, BW);
                end
                % for lane 2
                interest_vehicles = find(AssosiationArray{2}(time_idx,:) == -1);
                lane2{time_idx} = zeros(1,length(interest_vehicles));
                for veh_idx = 1:length(interest_vehicles)
                    lane2{time_idx}(veh_idx) = calculate_capacity(DistanceArray{2}(time_idx,interest_vehicles(veh_idx)), fc, sub6GHz_height, veh{2}(interest_vehicles(veh_idx)).car_height, TxPower, Noise, BW);
                end
                achv_capacity{ii}{time_idx} = sort([lane3{time_idx} , lane2{time_idx}],'descend');
                %achv_capacity{ii}{time_idx} = achv_capacity{ii}{time_idx} / size(achv_capacity{ii}{time_idx},2);
            end
            
        end
        achieved_capacity{jj,dd} = achv_capacity;
    end
end
time_step=delta;
explanation_string ='achieved capacity is a size(height) by size(dist) cell array, rows for height and columns for distances.Each element of this cell array another cell array for each different file i.e each simulation instace. Each of these cell arrays is another cell array for each time step that contains the capacity achieved at that time slot for each blocked vehicle.';
save_file_string = ['Achieved_capacities'];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'achieved_capacity','height','dist','BW','TxPower','sub6GHz_height','fc','Noise','time_step','explanation_string');


function C_per_second = calculate_capacity(d, fc, hBs, hm, TxPower, Noise, BW)
% d= distance btw BS and vehicle
% fc = carrier frequencyv (700 MHz for now)
% hBs = height of the base station (20m for now)
% hm = height of the vehicle
% TxPower = transmitter power of Bs (46 dBm for now)
% Noise = Noise per hertz
% BW = Total aggregated bandwidth (20 MHz for now)
a_hm = (1.1*log10(fc) - 0.7) * hm - (1.56*log10(fc)-0.8);
%% Original Okumura-Haka Model
A = 69.55 + 26.16 * log10(fc) - 13.82 * log10(hBs) - a_hm;
B = 44.9 - 6.55 * log10(hBs);
C = -2* (log10(fc/28))^2 - 5.4;
%% Cost 231- Hata Model
% A = 46.3 + 33.9 * log10(fc) - 13.82 * log10(hBs) - a_hm;
% B = 44.9 - 6.55 * log10(hBs);
% C = 0;
%%
PL = A+B*log10(d/1000)+C;
%% 3GPP macro for 1.8GHz 
% PL = 128.1 + 37.6 * log10 (d);
SNR = TxPower - PL - (Noise + 10*log10(BW)) ;
C_per_second = BW * min(log2(1+10^(SNR/10)), 10);
% C_per_second = BW * log2(1+10^(SNR/10));
end