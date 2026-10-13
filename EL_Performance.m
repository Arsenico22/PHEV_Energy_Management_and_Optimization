%% RENDIMENTO MOTORE ELETTRICO

function [P_batt, eta_EL] = EL_Performance(w_el, T_el, VP)

P_mech = w_el * T_el;
Losses = VP.kc * T_el^2 + VP.ki * abs(w_el) + VP.kw * abs(w_el)^3;
P_batt = P_mech + Losses + VP.P_inv_standby; 

if abs(P_mech) < 50 % Se la potenza alle ruote è meno di 50W
    eta_EL = 0; 

elseif P_mech > 0
    eta_EL = P_mech / P_batt;
else
    eta_EL = (abs(P_mech) - Losses - VP.P_inv_standby) / abs(P_mech); % In frenata, l'efficienza è il rapporto tra energia recuperata e meccanica
end

eta_EL = max(0, min(0.96, eta_EL)); % condizione di saturazione