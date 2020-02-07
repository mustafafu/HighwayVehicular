classdef CVArray < handle
    properties
        speed = 105/3600; %velocity of comm vehicle in m/sec
        mm_coverage = 200; %coverage of mmWave BSs.
        car_height = 2; % height of a car
        car_start = 0; %starting position of the vehicle
        car_end = 0; %end position of the vehicle
        car_length = 0;
        y_pos = 3.5;
        x_pos=0;
    end
    methods
        function obj = CVArray(x_start,x_end,lambda,mm_coverage,speed,y_pos)
            if nargin ~= 0
                % we will distribute vehicles for a strech
                % (when area of interest is btw 0 to 4km) 
                % around -4km to + 4km, so that we will have 8 km of 
                % vehicles coming to the area of interest
                total_strech = x_end - x_start;
                approx_matrix_size = ceil(total_strech / (1/lambda)); 
                distanceVec = exprnd(1/lambda,1,approx_matrix_size);
                %now we dont generate car lengths exponentially but from real world statistics 
                % for vehicles on NYS thruway
                lengths = [4.5, 9.5, 13.25];
                lengthProb = [0.855, 0.855+0.017, 0.855+0.017+0.128];
                H = rand(1, approx_matrix_size); % CDF to generate different types of vehicles
                % H1-H3 are the masks indicating vehicle type, we have 3 types of vehicles
                % refer to NYS types 2H, 2L 5L etc etc.
                H1 = (H <= lengthProb(1)) ;
                H2 = (H <= lengthProb(2) & H > lengthProb(1)) ;
                H3 = (H <= lengthProb(3) & H > lengthProb(2)) ;
                %carLengths = H1* lengths(1) + H2*lengths(2) + H3* lengths(3); % length of vehicles
                carHeights = H1.*normrnd(2.0, 0.1, [1, approx_matrix_size]) + H2.*normrnd(2.4, 0.1, [1, approx_matrix_size]) + H3.*normrnd(3.3, 0.15, [1, approx_matrix_size]);
                carLengths = H1.*normrnd(lengths(1), 1, [1, approx_matrix_size]) + H2.*normrnd(lengths(2), 1, [1, approx_matrix_size]) + H3.*normrnd(lengths(3), 1, [1, approx_matrix_size]);
                shiftedSum = [zeros(1,1) distanceVec(:,1:end-1)] + carLengths;
                carStartPositions = cumsum(shiftedSum,2); % ending positions of the vehicles on each lane
                carEndPositions = carStartPositions - carLengths; % starting position of the vehicles on eacl lane
                %shift the cars so that the last element of the cars which
                %is the furthest car is starting at 4000m so that the AoI
                %is filled with cars, then erase the cars which are not in
                %the x_start, x_end region.
                required_shifting = carStartPositions(end) - x_end;
                carStartPositions = carStartPositions - required_shifting;
                carEndPositions = carEndPositions - required_shifting;
                carStartPositions(carEndPositions<x_start) = [];
                carHeights(carEndPositions<x_start) = [];
                carEndPositions(carEndPositions<x_start) = [];
                % creating an array to store each car object
                how_many = size(carStartPositions,2);
                % Fill the array of vehicles with corresponding properties
                %we start from last element to allocate space for the
                %entire object so we wouldnt change size every loop
                for ii = how_many:-1:1
                    obj(ii).speed = speed;
                    obj(ii).y_pos = y_pos;
                    obj(ii).mm_coverage = mm_coverage;
                    % car_height of comm vehicles are 2m
                    % Anyway we generate car heights, we can assign them if
                    % needed.
                    obj(ii).car_height = 2;
                    obj(ii).car_start = carStartPositions(ii);
                    obj(ii).car_end = carEndPositions(ii);
                    obj(ii).car_length = obj(ii).car_start - obj(ii).car_end;
                    obj(ii).x_pos = 0.5*(obj(ii).car_start - obj(ii).car_end) + obj(ii).car_end;
                end
            end
        end
        function obj = moveCar(obj,time)
            how_many = size(obj,2);
            for ii = 1:how_many
                % moves the vehicles for given time
                obj(ii).car_start = obj(ii).car_start + obj(ii).speed * time;
                obj(ii).car_end = obj(ii).car_end + obj(ii).speed * time;
                obj(ii).x_pos = 0.5*(obj(ii).car_start - obj(ii).car_end) + obj(ii).car_end;
            end
        end
        % computes the LOS distance between the BS and Communicating
        % Vehicle, BS Array can be mmWave or sub6gs
        function distance = computeBsDistance(obj,BsArray)
            x1 = obj.x_pos;
            y1 = obj.y_pos;
            h1 = obj.car_height;
            xn = [BsArray.x_pos];
            yn = [BsArray.y_pos];
            hn = [BsArray.height];
            distance = sqrt((xn-x1).^2 + (yn-y1).^2 + (hn-h1).^2 );
        end
        
    end
end