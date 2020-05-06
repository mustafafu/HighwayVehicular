datadir = '/data';
nRarr = 4%1:1:5;
hRarr = 3%[1.5, 2, 3, 4, 5];

Dur_sim = zeros(length(hRarr),length(nRarr));

for NAI = 0:length(nRarr)*length(hRarr)-1
  hRidx = floor(mod(NAI,length(nRarr)*length(hRarr))/1/length(nRarr)) + 1;
  nRidx = mod(mod(NAI,length(nRarr)*length(hRarr)), length(nRarr)) + 1;
  
  hBs = hRarr(hRidx);  % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
  numBs = nRarr(nRidx); % # of BSs in coverage area
  
  string_2 = [datadir,'/1LaneCombined', '/combined-numBS_',num2str(numBs),'-heightBS_',num2str(hBs),'-DurationList'];
  string_2 = strrep(string_2,'.',',');
  load(['.',string_2,'.mat'])
  
  
  Dur_sim(hRidx,nRidx) = mean(mean(durationList));
end

% h=figure();
semilogy(nRarr,Dur_sim(1,:),'--bx');
hold on;
semilogy(nRarr,Dur_sim(2,:),'--b*');
hold on;
semilogy(nRarr,Dur_sim(3,:),'--bs');
hold on;
semilogy(nRarr,Dur_sim(4,:),'--bp');
hold on;
semilogy(nRarr,Dur_sim(5,:),'--b+');
hold on;
grid on;

legend('Simulation - 1.5m',...
'Simulation - 2m',...
'Simulation - 3m',...
'Simulation - 4m',...
'Simulation - 5m')
xlabel('Number of Base Stations (nBs)')
ylabel('Average Blockage Duration (ms)')
title('Blockage Simulation focused on Vehicle of Interest')
% print(h,"./Figures/plotBSvsNBvsHeight.eps","-deps");
% save_fig_string = strcat(['./Figures/','VehicleofInterestSimulation','.jpg' ]);
% saveas(h,save_fig_string)