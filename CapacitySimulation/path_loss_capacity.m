function C_per_second = path_loss_capacity(d, fc, hBs, hm, TxPower, Noise, BW, NoiseFig)
% d= distance btw BS and vehicle
% fc = carrier frequencyv (700 MHz for now)
% hBs = height of the base station (20m for now)
% hm = height of the vehicle
% TxPower = transmitter power of Bs (46 dBm for now)
% Noise = Noise per hertz
% BW = Total aggregated bandwidth (20 MHz for now)
a_hm = (1.1*log10(fc) - 0.7) * hm - (1.56*log10(fc)-0.8);
%% Original Okumura-Haka Model
A = 69.55 + 26.16 * log10(fc) - 13.82 * log10(hBs) - a_hm;
B = 44.9 - 6.55 * log10(hBs);
C = -2* (log10(fc/28))^2 - 5.4;
%% Cost 231- Hata Model
% A = 46.3 + 33.9 * log10(fc) - 13.82 * log10(hBs) - a_hm;
% B = 44.9 - 6.55 * log10(hBs);
% C = 0;
%%
PL = A+B*log10(d/1000)+C;
%% 3GPP macro for 1.8GHz 
% PL = 128.1 + 37.6 * log10 (d);
SNR = TxPower - PL - (Noise + 10*log10(BW)) - NoiseFig ;
C_per_second = BW * min(log2(1+10^(SNR/10)), 10);
% C_per_second = BW * log2(1+10^(SNR/10));
end