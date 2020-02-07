function [carStartPositions, carLengths, carHeights] = generateBlockers(lambda,mu,blockingLanes,sizeMat)

jj = length(blockingLanes);

distanceVec = exprnd(1/lambda,jj,sizeMat);
%now we dont generate car lengths exponentially but from real world statistics 
% for vehicles on NYS thruway
%S = exprnd(1/mu,jj,sizeMat);
lengths = [4.5, 9.5, 13.25];
lengthProb = [0.855, 0.855+0.017, 0.855+0.017+0.128];
H = rand(jj, sizeMat); % CDF to generate different types of vehicles
% H1-H3 are the masks indicating vehicle type, we have 3 types of vehicles
% refer to NYS types 2H, 2L 5L etc etc.
H1 = (H <= lengthProb(1)) ;
H2 = (H <= lengthProb(2) & H > lengthProb(1)) ;
H3 = (H <= lengthProb(3) & H > lengthProb(2)) ;
%carLengths = H1* lengths(1) + H2*lengths(2) + H3* lengths(3); % length of vehicles
carHeights = H1.*normrnd(2.0, 0.1, [jj, sizeMat]) + H2.*normrnd(2.4, 0.1, [jj, sizeMat]) + H3.*normrnd(3.3, 0.15, [jj, sizeMat]);
carLengths = H1.*normrnd(lengths(1), 1, [jj, sizeMat]) + H2.*normrnd(lengths(2), 1, [jj, sizeMat]) + H3.*normrnd(lengths(3), 1, [jj, sizeMat]);
shiftedSum = distanceVec + [zeros(jj,1) carLengths(:,1:end-1)];
carStartPositions = cumsum(shiftedSum,2); % starting positions of the vehicles on each lane

end

