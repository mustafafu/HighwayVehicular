height = [1.5,2,3,6];
dist = 75:50:350;
time_step = 3;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
ll=numLane;
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end



Offloaded_vehicle_numbers = cell(length(height),length(dist));
Average_capacity_offloaded_vehicles = cell(length(height),length(dist));

for jj = 1:length(height)
    for dd = 1:length(dist)
        get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        num_of_offloaded = cell(length(files),1);
        avg_cap_offloaded = cell(length(files),1);
        P_b = cell(length(files),1);
        for ii=1:length(files)
            load(files(ii).name)
            BlockedTimes = [(AssosiationArray{2} == -1), (AssosiationArray{3} == -1)];
            Capacities = [s6_CapacityArray{2},s6_CapacityArray{3}];
            num_of_offloaded{ii} = sum(BlockedTimes,2);
            interest_capacities = Capacities.* (Capacities > 0);
            % it is possible to get a NAN in this case, that means at that
            % time instance there was not a blocked vehicle to create the
            % notion of average. so its 0/0 -> Nan
            % sum_capacities / number_ofloaded.
            avg_cap_offloaded{ii} = sum(interest_capacities,2) ./ sum(BlockedTimes,2);
        end
        % record it for distance and height
        Offloaded_vehicle_numbers{jj,dd} = num_of_offloaded;
        Average_capacity_offloaded_vehicles{jj,dd} = num_of_offloaded;
    end
end

save_file_string = ['OffloadCounts', num2str(ll)];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'Offloaded_vehicle_numbers','Average_capacity_offloaded_vehicles','dist','height','time_step','Parameters');



