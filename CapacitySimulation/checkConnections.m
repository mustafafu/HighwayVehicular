function [ tempDistance , tempAssosiation, tempCapacity ] = checkConnections(veh,mmWaveBsArray,sub6GBs,Cm_inRange_idx_start,Cm_inRange_idx_end,CV_lane,mm_coverage)
% for each communicating vehicle in the region
tempDistance = zeros(1,length(veh{CV_lane}));
tempAssosiation = zeros(1,length(veh{CV_lane}));
tempCapacity = -1 * ones(1,length(veh{CV_lane}));
for Cm_idx = Cm_inRange_idx_start : Cm_inRange_idx_end
    %antenna position of communicating vehicle
    Cm_veh_pos = veh{CV_lane}(Cm_idx).x_pos;
    %LOS coverage range for this antenna
    cov_range_start = Cm_veh_pos-mm_coverage;
    cov_range_end = Cm_veh_pos+mm_coverage;
    % mmWave Base Stations in this coverage area
    inRange_Bs = mmWaveBsArray(mmWaveBsArray.find_Bs_in_range(cov_range_start,cov_range_end));
    Cv_mmBs_distance = veh{CV_lane}(Cm_idx).computeBsDistance(inRange_Bs);
    min_dist = 9999;
    min_idx = 9999;
    Cv_s6Bs_distance = veh{CV_lane}(Cm_idx).computeBsDistance(sub6GBs);
    for Bs_idx = length(inRange_Bs):-1:1
        possibleBlockers = [];
        for lane = 1 : CV_lane-1
            possibleBlockers = [possibleBlockers, veh{lane}(veh{lane}.find_Bv_in_range(inRange_Bs(Bs_idx),veh{CV_lane}(Cm_idx))) ];
        end
        if ~isempty(possibleBlockers)
            Cv_mmBs_distance(Bs_idx) = -1;
        else
            if Cv_mmBs_distance(Bs_idx)<min_dist
                min_dist = Cv_mmBs_distance(Bs_idx);
                min_idx = Bs_idx;
            end
        end
    end
%     [min_dist,min_idx]=min(Cv_mmBs_distance([Cv_mmBs_distance > 0]));
    if (min_dist<9998)
        tempDistance(1,Cm_idx) = min_dist;
        tempAssosiation(1,Cm_idx) = mmWaveBsArray.find_idx_in_main_array(inRange_Bs(min_idx));
    else
        tempDistance(1,Cm_idx) = Cv_s6Bs_distance;
        tempAssosiation(1,Cm_idx) = -1; %-1 indicated it is associated with the sub 6Ghz Base station
        % Compute capacity here, if we are in this condition that means
        % this vehicle is connected to a sub6GHZ BS.
        tempCapacity(1,Cm_idx) = path_loss_capacity(Cv_s6Bs_distance, sub6GBs.fc, sub6GBs.height, veh{CV_lane}(Cm_idx).car_height, sub6GBs.TxPower, sub6GBs.Noise, sub6GBs.BW, sub6GBs.NoiseFig);
    end
end
end

