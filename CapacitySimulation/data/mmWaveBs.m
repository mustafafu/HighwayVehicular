classdef mmWaveBs
    properties
        %default values for a mmWaveBs
        x_pos = 0;
        y_pos = 7.5;
        height = 2;
        R_coverage = 200;
    end
    methods
        function obj = mmWaveBs(xstart,xend,seperation,mm_y_pos,mm_hBs,mm_coverage)
            if nargin ~= 0
                how_many = floor((xend-xstart)/seperation)+2;
                obj(how_many,1) = obj;
                obj(1).x_pos = xstart;
                obj(1).y_pos = mm_y_pos;
                obj(1).height = mm_hBs;
                obj(1).R_coverage = mm_coverage;
                for ii = 2:how_many
                    distance = seperation;
%                     distance = seperation+normrnd(0,sqrt(seperation/2));
%                     while (seperation-distance) < 0
%                         distance = seperation;
% %                         distance = seperation+normrnd(0,sqrt(seperation/2));
%                     end
                    obj(ii).x_pos = obj(ii-1).x_pos+distance;
                    obj(ii).y_pos = mm_y_pos;
                    obj(ii).height = mm_hBs;
                    obj(ii).R_coverage = mm_coverage;
                end
                obj([obj.x_pos]>xend) = [];
            end
        end
        %This function will spit out the base station indices that are in
        %the region (range_start,range_end)
        function inRange = find_Bs_in_range(obj,range_start,range_end)
            inRange = [[obj.x_pos] < range_end] & [[obj.x_pos] > range_start];
        end
        %This function find where is the mmwave object with certain
        %parameters is located in the array.
        function idx = find_idx_in_main_array(mainArray,mmWaveObj)
            idx=find([mainArray.x_pos] == mmWaveObj.x_pos);
        end
    end
end