height = [1.5,2,3,6];
dist = [75,100,125,150,175:50:350];
time_step = 3;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

requirement_array = [];
requirement_name_array = {};
requirement = 128*1e5;

Duration = cell(length(height),length(dist));
Blockage_Probability = cell(length(height),length(dist));

for jj = 1:length(height)
    for dd = 1:length(dist)
        get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        num_of_offloaded = cell(length(files),1);
        P_b = cell(length(files),1);
        for ii=1:length(files)
            load(files(ii).name)
            combined_data = [AssosiationArray{2}, AssosiationArray{3}];
            BlockedTimes = [(AssosiationArray{2} == -1), (AssosiationArray{3} == -1)];
            Capacities = [s6_CapacityArray{2},s6_CapacityArray{3}];
            
            isCapacityAchieved = zeros(size(BlockedTimes));
            
            for rr = 1:size(Capacities,1)
                current_vehicles = find(Capacities(rr,:)>0);
                current_capacities = Capacities(rr,current_vehicles);
                [sorted_capacities, sorted_veh_idx] = sort(current_capacities,'descend');
                served_vehicles = sorted_veh_idx(cumsum(requirement ./ sorted_capacities) < 1);
                isCapacityAchieved(rr,current_vehicles) = -1;
                isCapacityAchieved(rr,current_vehicles(served_vehicles)) = 1;
            end
            
            OutageTimes = (isCapacityAchieved == -1);
            Diff = [zeros(1,size(OutageTimes,2)); OutageTimes(2:end,:)-OutageTimes(1:end-1,:)];
            Diff(1,:) = isCapacityAchieved(1,:)==-1;
            Diff(end,:) = Diff(end,:) - (isCapacityAchieved(end,:)==-1);
            BlockageArrival = (Diff==1);
            BlockageDeparture = (Diff==-1);
            [rowA,~] = find(BlockageArrival);
            [rowD,~] = find(BlockageDeparture);
            num_of_offloaded{ii} = sort(rowD-rowA);
            
            mask = (combined_data~=00);
            meaningful_data = combined_data(mask);
            num_blockages = sum(meaningful_data == -1);
            P_b{ii}=num_blockages / length(meaningful_data);
        end
        Duration{jj,dd} = num_of_offloaded; %for height jj and distance dd
        Blockage_Probability{jj,dd} = P_b;
    end
end


save_file_string = ['CombinedOutage'];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'Duration','Blockage_Probability','dist','height','time_step','Parameters');

