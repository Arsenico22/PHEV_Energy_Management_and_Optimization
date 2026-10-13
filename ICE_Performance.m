%% RENDIMENTO MOTORE A COMBUSTIONE 1.4 TSI

function [dm, eta] = ICE_Performance(w, T, VP)

if w < VP.w_idle_ICE
   
    T_max_dyn = 0; % Sotto il minimo il motore non può erogare coppia

elseif w < VP.w_start_plateau

    T_max_dyn = VP.T_idle + (VP.T_max_ICE - VP.T_idle) * (w - VP.w_idle_ICE) / (VP.w_start_plateau - VP.w_idle_ICE); % Rampa di salita della coppia

elseif w <= VP.w_end_plateau

    T_max_dyn = VP.T_max_ICE;  % Plateau di coppia massima (circa tra 1550 e 3500 RPM)
else

    T_max_dyn = VP.T_max_ICE - VP.k_torque_ice * (w - VP.w_end_plateau)^2; % Calo ad alti regimi
end


if T <= 0
    dm = 0;
    eta = 0; % Se la coppia richiesta è zero o negativa, il consumo è nullo.
    return;
end

if T > T_max_dyn || w > VP.w_max_ICE
    dm = 10; % Se la coppia richiesta eccede il limite dinamico o i giri massimi, introduco penalità
    eta = 0;
    return;
end

% Definisco il Best Efficiency Point (BEP)

w_opt = 2500 * (pi/30); % Regime di massimo rendimento (rad/s)
T_opt = 160; % Coppia di massimo rendimento (Nm)
eta_max = 0.38; % Rendimento massimo (38%)

eta = eta_max - 1.2e-6 * (w - w_opt)^2 - 1.5e-5 * (T - T_opt)^2; % Calcolo rendimento basato sulla distanza dal punto ottimo,
% compresa di coefficienti di curvatura

eta = max(0.10, min(0.40, eta)); % saturazione 

P_mech = T * w; % Potenza meccanica prodotta

dm = P_mech / (eta * VP.Q_lhv); % Calcolo massa di combustibile al secondo

end