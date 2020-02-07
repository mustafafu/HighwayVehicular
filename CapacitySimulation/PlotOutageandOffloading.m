
mm_hBs_array = [1.5, 2, 3, 4];
% num_bs in coverage area is mm_coverage * 2 / mm_seperation
mm_seperation_array = 75:25:350; % how many meters between consecutive base stations

load('MeanOutage_MeanOffloading.mat')
P_off = zeros(length(mm_seperation_array),length(mm_hBs_array));
for dd=1:length(mm_seperation_array)
    for hh=1:length(mm_hBs_array)
        P_off(dd,hh)= mean(mean(P_offload{dd,hh}));
    end
end

figure();
semilogy(mm_seperation_array,P_off(:,1),'-xb');
% set(gca, 'XDir','reverse')
hold on;
grid on;
semilogy(mm_seperation_array,P_off(:,2),'-+b');
semilogy(mm_seperation_array,P_off(:,3),'-*b');
semilogy(mm_seperation_array,P_off(:,4),'-sb');
legend('h_{BS} = 1.5m','h_{BS} = 2m','h_{BS} = 3m','h_{BS} = 4m')


qos_capacity_requirements = [1.28,2.56,2.88,10,14,29]*10^6; % per second, per vehicle use case requirements
P_out=zeros(length(mm_seperation_array),length(mm_hBs_array),length(qos_capacity_requirements));
for dd=1:length(mm_seperation_array)
    for hh=1:length(mm_hBs_array)
        P_out(dd,hh,:)= mean(mean(P_outage{dd,hh}));
    end
end
for ss=1:length(qos_capacity_requirements)
    figure()
    semilogy(mm_seperation_array,P_out(:,1,ss),'-xr');
    % set(gca, 'XDir','reverse')
    hold on;
    grid on;
    semilogy(mm_seperation_array,P_out(:,2,ss),'-+r');
    semilogy(mm_seperation_array,P_out(:,3,ss),'-*r');
    semilogy(mm_seperation_array,P_out(:,4,ss),'-sr');
    legend('h_{BS} = 1.5m','h_{BS} = 2m','h_{BS} = 3m','h_{BS} = 4m')
    title(['Outage Probability Capacity Requirement = ',num2str(qos_capacity_requirements(ss)/1e6),' Mbps'])
end





