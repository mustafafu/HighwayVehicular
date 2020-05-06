max_bs=6;
max_lane=3;
T_littles = zeros(max_lane,max_bs);
mean_durations = zeros(max_lane,max_bs);

for ii=1:max_lane
    for jj=1:max_bs
        load_string = ['numBS=', num2str(jj), '-numBlockingLanes=', num2str(ii), '-ThrPblock-MarkovSSProbs-markovNumericDurations-Littleslaw-nbindices.mat'];
        load(load_string)
        T_littles(ii,jj) = T_little;
        load_string2 = ['numBS=', num2str(jj), '-numBlockingLanes=', num2str(ii), '-BlockageDurationPercentage-BlockageDurations.mat'];
        load(load_string2);
        mean_durations(ii,jj)=mean(durationMat(durationMat~=0));
    end
end

semilogy(1:max_bs,T_littles(1,:),'--rx');
hold on;
semilogy(1:max_bs,T_littles(2,:),'--r*');
hold on;
semilogy(1:max_bs,T_littles(3,:),'--rs');
hold on;
grid on;


semilogy(1:max_bs,mean_durations(1,:),'--bx');
hold on;
semilogy(1:max_bs,mean_durations(2,:),'--b*');
hold on;
semilogy(1:max_bs,mean_durations(3,:),'--bs');
hold on;
grid on;


legend('Littles Law 1 BL','Littles Law 2 BL','Littles Law 3 BL',...
    'Simulation 1 BL','Simulation 2 BL','Simulation 3 BL')
xlabel('Number of Base Stations (nBs)')
ylabel('Average Blockage Duration')