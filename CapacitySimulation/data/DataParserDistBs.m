height = [1.5,2,3,4];
dist = 75:50:350;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

P_b = cell(numLane,1);
P_blockage = cell(numLane,1);
for ll = numLane:-1:1
    h=figure(ll);
    plot_strings = ['--x';'--s';'--p';'--*'];
    for jj = 1:length(height)
        P_blockage{ll} = zeros(length(dist),1);
        for dd = 1:length(dist)
            get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
            get_file_string = strrep(get_file_string,'.',',');
            files = dir([get_file_string,'*']);
            P_b{ll} = zeros(1,length(files));
            for ii=1:length(files)
                load(files(ii).name)
                mask = (AssosiationArray{ll} ~= 0);
                meaningful_data = AssosiationArray{ll}(mask);
                num_blockages = sum(meaningful_data == -1);
                P_b{ll}(ii) = num_blockages / length(meaningful_data);
            end
            P_blockage{ll}(dd) = mean(P_b{ll});
        end
        semilogy(dist,P_blockage{ll},plot_strings(jj,:));
        grid on;
        hold on
    end
    legend('Simulation - 1.5m',...
    'Simulation - 2m',...
    'Simulation - 3m',...
    'Simulation - 4m')
    xlabel('Distance between  Base Stations (dBs)')
    ylabel('Probability of Blockage (P_B)')
    title(['Blockage Simulation Assoc. Method on Lane-',num2str(ll)]);
    set(h.CurrentAxes, 'Xdir', 'reverse')
%     print(h,['../Figures/plotBSvsNBvsHeightLane-',num2str(ll),'.eps'],"-deps");
end

% 
% title('Blockage Simulation Association Method')
% print(h,"../Figures/plotBSvsNBvsHeight.eps","-deps");
% save_fig_string = strcat(['../Figures/','CapacityMethodSimulation','.jpg' ]);
% saveas(h,save_fig_string)
% 
