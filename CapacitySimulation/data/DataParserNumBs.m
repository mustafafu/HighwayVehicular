height = [2,3,4];
dist = 75:25:350;
numbs_array = 1:0.25:4;
mm_coverage = 200;
ha=2;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
  printf('vehicle is not on the road')
  exit
end
widthLane = 3.5; % how wide each lane is?

h=figure();
plot_strings = ['--x';'--s';'--p';'--*'];

P_bl = cell(length(height),1);
for jj = 1:length(height)
     

    P_blockage = zeros(length(numbs_array),1);
    for dd = 1:length(numbs_array)
         % Compute coverage area
temp = sqrt(mm_coverage^2-(height(jj)-ha)^2);
temp = sqrt(temp^2-((whereisCV-1/2)*widthLane)^2);
Rcov = temp*2; % Horizontal LoS coverage distance

% Compute inter-BS distance
mm_seperation = Rcov/numbs_array(dd);
        get_file_string = ['distBS_',num2str(mm_seperation),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        P_b = zeros(1,length(files));
        for ii=1:length(files)
            load(files(ii).name)
            mask = (AssosiationArray ~= 0);
            meaningful_data = AssosiationArray(mask);
            num_blockages = sum(meaningful_data == -1);
            P_b(ii) = num_blockages / length(meaningful_data);
        end
        P_blockage(dd) = mean(P_b);
    end
    semilogy((numbs_array),fliplr(P_blockage),plot_strings(jj,:));
    grid on;
    hold on
end


legend('Simulation - 1.5m',...
'Simulation - 2m',...
'Simulation - 3m',...
'Simulation - 4m')
xlabel('Number of Base Stations (nBs)')
ylabel('Probability of Blockage (P_B)')
title('Blockage Simulation Association Method')
% print(h,"../Figures/plotBSvsNBvsHeight.eps","-deps");
% save_fig_string = strcat(['../Figures/','CapacityMethodSimulation','.jpg' ]);
% saveas(h,save_fig_string)

