height = [1.5,2,3,4];
dist = 75:25:350;
time_step = 3;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

for ll=2:3

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
            BlockedTimes = (AssosiationArray{ll} == -1);
            Diff = [zeros(1,size(BlockedTimes,2)); BlockedTimes(2:end,:)-BlockedTimes(1:end-1,:)];
            Diff(1,:) = AssosiationArray{ll}(1,:)==-1;
            Diff(end,:) = Diff(end,:) - (AssosiationArray{ll}(end,:)==-1);
            BlockageArrival = (Diff==1);
            BlockageDeparture = (Diff==-1);
            blockageDurations = cell(1,size(Diff,2));
            for veh_idx = 1: size(Diff,2)
                starts = find(BlockageArrival(:,veh_idx));
                ends = find(BlockageDeparture(:,veh_idx));
                if length(starts) ~= length(ends)
                    veh_idx
                end
                blockageDurations{veh_idx} = (ends-starts).';
            end
            num_of_offloaded{ii} = sort(cell2mat(blockageDurations).');
            mask = (AssosiationArray{ll} ~= 0);
            meaningful_data = AssosiationArray{ll}(mask);
            num_blockages = sum(meaningful_data == -1);
            P_b{ii} = num_blockages / length(meaningful_data);
        end
        Duration{jj,dd} = num_of_offloaded; %for height jj and distance dd
        Blockage_Probability{jj,dd} = P_b;
    end
end

save_file_string = ['Latency-Lane', num2str(ll)];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'Duration','Blockage_Probability','dist','height','time_step');

end
