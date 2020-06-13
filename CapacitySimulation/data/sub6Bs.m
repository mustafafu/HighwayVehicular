classdef sub6Bs
    properties
        x_pos = 2000;
        y_pos = 7.5;
        height = 20;
        TxPower = 46 ; %dBm
        Noise = -173.9 ; %dBm per hertz
        fc = 700 ; % Hz
        BW = 20 * 1e6; % Hz
        NoiseFig
    end
    methods
        function obj = sub6Bs(x_pos,y_pos,height,TxPower,Noise,fc,BW,NoiseFig)
            if nargin ~= 0
                obj.x_pos = x_pos;
                obj.y_pos = y_pos;
                obj.height = height;
                obj.TxPower = TxPower;
                obj.Noise = Noise;
                obj.fc = fc;
                obj.BW = BW;
                obj.NoiseFig = NoiseFig;
            end
        end
    end
end
