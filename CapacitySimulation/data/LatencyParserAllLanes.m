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

ll_range=[2,3];

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
            tot_veh = 0;
            tot_weighted_P_b = 0;
            for ll=ll_range
                BlockedTimes = (AssosiationArray{ll} == -1);
                Diff = [zeros(1,size(BlockedTimes,2)); BlockedTimes(2:end,:)-BlockedTimes(1:end-1,:)];
                Diff(1,:) = AssosiationArray{ll}(1,:)==-1;
                Diff(end,:) = Diff(end,:) - (AssosiationArray{ll}(end,:)==-1);
                BlockageArrival = (Diff==1);
                BlockageDeparture = (Diff==-1);
                blockageDurations = cell(1,size(Diff,2));
                [rowA,~] = find(BlockageArrival);
                [rowD,~] = find(BlockageDeparture);
                num_of_offloaded{ii} = [num_of_offloaded{ii};sort(rowD-rowA)];
                mask = (AssosiationArray{ll} ~= 0);
                meaningful_data = AssosiationArray{ll}(mask);
                num_blockages = sum(meaningful_data == -1);
                num_vehicles = size(AssosiationArray{ll},2);
                tot_veh = tot_veh + num_vehicles;
                tot_weighted_P_b = tot_weighted_P_b + num_vehicles*num_blockages / length(meaningful_data);
            end
            P_b{ii} = tot_weighted_P_b/tot_veh;
        end
        Duration{jj,dd} = num_of_offloaded; %for height jj and distance dd
        Blockage_Probability{jj,dd} = P_b;
    end
end

save_file_string = ['LatencyAll'];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'Duration','Blockage_Probability','dist','height','time_step','Parameters');

