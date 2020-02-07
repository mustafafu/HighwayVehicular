height = [1.5,2,3,4];
dist = 75:25:350;
%% Road Parameters
numLane = 3; % number of lanes
whereisCV = 3; % lane on which the communicating vehicles move
if whereisCV>numLane
    printf('vehicle is not on the road')
    exit
end

low_reliability = 99.9/100;
medium_reliability = 99.99/100;
high_reliability = 99.999/100;


%for ll = numLane
plot_strings = ['--x';'--s';'--p';'--*'];
ll=3;
ConnectedTosub6Ghz = cell(length(height),length(dist));
Percentage_ConnectedTosub6Ghz = cell(length(height),length(dist));
low_reliability_percentage = zeros(length(height),length(dist));
medium_reliability_percentage = zeros(length(height),length(dist));
high_reliability_percentage = zeros(length(height),length(dist));
low_reliability_number = zeros(length(height),length(dist));
medium_reliability_number = zeros(length(height),length(dist));
high_reliability_number= zeros(length(height),length(dist));
for jj = 1:length(height)
    for dd = 1:length(dist)
        get_file_string = ['distBS_',num2str(dist(dd)),'-heightBS_',num2str(height(jj))];
        get_file_string = strrep(get_file_string,'.',',');
        files = dir([get_file_string,'*']);
        num_of_offloaded = cell(length(files),1);
        percent_of_offloaded = cell(length(files),1);
        for ii=1:length(files)
            load(files(ii).name)
            num_of_offloaded{ii} = sum((AssosiationArray{ll} == -1),2);
            percent_of_offloaded{ii} = num_of_offloaded{ii}./sum((AssosiationArray{ll} ~= 0),2);
        end
        ConnectedTosub6Ghz{jj,dd} = sort(cell2mat(num_of_offloaded)); %for height jj and distance dd
        Percentage_ConnectedTosub6Ghz{jj,dd} = sort(cell2mat(percent_of_offloaded));
        l_p = length(Percentage_ConnectedTosub6Ghz{jj,dd});
        l_n = length(ConnectedTosub6Ghz{jj,dd});
        if l_p > 0 && l_n > 0
            low_reliability_percentage(jj,dd) = Percentage_ConnectedTosub6Ghz{jj,dd}(floor(l_p * low_reliability));
            medium_reliability_percentage(jj,dd) = Percentage_ConnectedTosub6Ghz{jj,dd}(floor(l_p * medium_reliability));
            high_reliability_percentage(jj,dd) = Percentage_ConnectedTosub6Ghz{jj,dd}(floor(l_p * high_reliability));
            low_reliability_number(jj,dd) = ConnectedTosub6Ghz{jj,dd}(floor(l_n * low_reliability));
            medium_reliability_number(jj,dd) = ConnectedTosub6Ghz{jj,dd}(floor(l_n * medium_reliability));
            high_reliability_number(jj,dd) = ConnectedTosub6Ghz{jj,dd}(floor(l_n * high_reliability));
        end
    end
%     figure(1);
%     hold on;
%     plot(dist,low_reliability_percentage(jj,:),plot_strings(jj,:));
%     grid on;
%     hold on
%     
%     figure(2);
%     hold on;
%     plot(dist,medium_reliability_percentage(jj,:),plot_strings(jj,:));
%     grid on;
%     hold on;
%     
%     figure(3);
%     hold on;
%     plot(dist,high_reliability_percentage(jj,:),plot_strings(jj,:));
%     grid on;
%     hold on;
end

save_file_string = ['Lane', num2str(ll)];
save_file_string = strrep(save_file_string,'.',',');
save(save_file_string, 'ConnectedTosub6Ghz','Percentage_ConnectedTosub6Ghz');
% 
% figure(1)
% legend('Simulation - 1.5m',...
%     'Simulation - 2m',...
%     'Simulation - 3m',...
%     'Simulation - 4m')
% xlabel('Distance between  Base Stations (m)')
% ylabel('Percentage of Vehicles Offloaded to sub 6 GHz')
% title(['Low Reliability Lane ',num2str(ll)]);
% print(['../Figures/LowOffloadPercentage-Lane',num2str(ll),'.eps'],"-deps");
% 
% figure(2)
% legend('Simulation - 1.5m',...
%     'Simulation - 2m',...
%     'Simulation - 3m',...
%     'Simulation - 4m')
% xlabel('Distance between  Base Stations (m)')
% ylabel('Percentage of Vehicles Offloaded to sub 6 GHz')
% title(['Medium Reliability Lane ',num2str(ll)]);
% print(['../Figures/MediumOffloadPercentage-Lane',num2str(ll),'.eps'],"-deps");
% 
% 
% figure(3)
% legend('Simulation - 1.5m',...
%     'Simulation - 2m',...
%     'Simulation - 3m',...
%     'Simulation - 4m')
% xlabel('Distance between  Base Stations (m)')
% ylabel('Percentage of Vehicles Offloaded to sub 6 GHz')
% title(['High Reliability Lane ',num2str(ll)]);
% print(['../Figures/HighOffloadPercentage-Lane',num2str(ll),'.eps'],"-deps");
% %     print(h,['../Figures/plotBSvsNBvsHeightLane-',num2str(ll),'.eps'],"-deps");
% %end

