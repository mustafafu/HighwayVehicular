classdef sub6Bs
    properties
        x_pos = 2000;
        y_pos = 7.5;
        height = 20;
    end
    methods
        function obj = sub6Bs(x_pos,y_pos,height)
            if nargin ~= 0
                obj.x_pos = x_pos;
                obj.y_pos = y_pos;
                obj.height = height;
            end
        end
    end
end
