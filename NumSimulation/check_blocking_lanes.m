function blockingLanes = check_blocking_lanes(hBs,ha,hb,ii)
%CHECK_BLOCKING_LANES returns currently blocking lane numbers
%   Given BS height, vehicle antenna height, blocker vehicle height,
%   current driving lane, returns the lanes blocking the current lane.
blockingLanes = [];
for jj = 1:ii-1
    criticalHeight = ha+(hBs-ha)*(ii-jj)/(ii-1/2); %using triangle similarity.
    if(hb>criticalHeight) % blocking, record remaining lanes & exit
        blockingLanes = jj:1:(ii-1);
        break;
    end
end

end

