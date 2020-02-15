classdef BVArray < handle
    properties
        speed = 100/3600; %velocity of comm vehicle in m/sec
        mm_coverage = 200; %coverage of mmWave BSs.
        car_height = 2; % height of a car
        car_start = 0; %starting position of the vehicle
        car_end = 0; %end position of the vehicle
        car_length = 0;
        y_pos = 3.5;
        x_pos=0;
    end
    methods
        %constructor
        function obj = BVArray(x_start,x_end,lambda,mm_coverage,speed,y_pos)
            if nargin ~= 0
                % we will distribute vehicles for a strech
                % (when area of interest is btw 0 to 4km) 
                % around -10km to + 4km, so that we will have 14 km of 
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
                %start from last element to not change matrix size
                %everytime
                for ii = how_many:-1:1
                    obj(ii).speed = speed;
                    obj(ii).y_pos = y_pos;
                    %% Possible fix for dip issue
                    obj(ii).mm_coverage = mm_coverage + normrnd(0,sqrt(mm_coverage/2));
%                     obj(ii).mm_coverage = mm_coverage;
                    obj(ii).car_height = carHeights(ii);
                    obj(ii).car_start = carStartPositions(ii);
                    obj(ii).car_end = carEndPositions(ii);
                    obj(ii).car_length = obj(ii).car_start - obj(ii).car_end;
                    obj(ii).x_pos = 0.5*(obj(ii).car_start - obj(ii).car_end) + obj(ii).car_end;
                end
            end
        end
        %update position of the vecihle
        function obj = moveCar(obj,time)
            how_many = size(obj,2);
            for ii = 1:how_many
                % moves the vehicles for given time
                obj(ii).car_start = obj(ii).car_start + obj(ii).speed * time;
                obj(ii).car_end = obj(ii).car_end + obj(ii).speed * time;
                obj(ii).x_pos = 0.5*(obj(ii).car_start - obj(ii).car_end) + obj(ii).car_end;
            end
        end
        % Checks the critical height in that particular lane in order to
        % block the base station and communicating vehicle LOS. Checks the
        % projection of this LOS ray to the x-y plane and finds the x
        % coordinate of the point of intersection of this projection and
        % the y=lane_y line so that it finds the x value, and compares car
        % start and car end values with this and sees if there is a car
        % with enough height starts before this x and ends after this x
        % value, i.e checks if there is any car blocking the LOS. Returns
        % the index of that car.
        function inRange = find_Bv_in_range(obj,mmWaveBsObj,CvObj)
            h1 = CvObj.car_height;
            y1 = CvObj.y_pos;
            x1 = CvObj.x_pos;
            h2 = mmWaveBsObj.height;
            y2 = mmWaveBsObj.y_pos;
            x2 = mmWaveBsObj.x_pos;
            y3 = obj.y_pos;
            x3 = (x2-x1)*(y3-y1)/(y2-y1) + x1;
            h3 = (h2-h1)*(y3-y1)/(y2-y1) + h1;
            inRange = [[obj.car_end] < x3] & [[obj.car_start] > x3] & [[obj.car_height] > h3] ;
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