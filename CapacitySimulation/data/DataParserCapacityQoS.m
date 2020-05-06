height = [1.5,2,3,4];
dist = 75:50:350;
qos_capacity_requirements = [1.28,2.56,2.88,10,14,29]*10^6; % per second, per vehicle use case requirements
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

P_offload = cell(length(dist),length(height));
P_outage = cell(length(dist),length(height));


for dd = 1:length(dist)
    for jj = 1:length(height)
        get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        P_offload{dd,jj} = zeros(length(files),numLane);
        P_outage{dd,jj} = zeros(length(files),numLane,length(qos_capacity_requirements));
        for ii=1:length(files)
            load(files(ii).name)
            for ll = numLane:-1:1
                mask = (AssosiationArray{ll} ~= 0);
                meaningful_data = AssosiationArray{ll}(mask);
                num_blockages = sum(meaningful_data == -1);
                P_offload{dd,jj}(ii,ll) = num_blockages / length(meaningful_data);
            end
            for ll = numLane:-1:1
                for ss=1:length(qos_capacity_requirements)
                    mask = (isCapacityAchieved{ll,ss} ~= 0);
                    meaningful_data = isCapacityAchieved{ll,ss}(mask);
                    num_outages = sum(meaningful_data == -1);
                    P_outage{dd,jj}(ii,ll,ss) = num_outages / length(meaningful_data);
                end
            end
        end
    end
end


Description=['P_offload and P_outage are offload and outage probabilities, respectively. Both of them are 2D-cell arrays where first index is for base station distance and the second index is for BS height. '];
Desc_P_off=['each element of P_off is a matrix size num_files by numLanes'];
Desc_P_out=['each element of P_out is a matrix size num_files by numLanes by numServices'];

save_string = ['MeanOutage_MeanOffloading'];



