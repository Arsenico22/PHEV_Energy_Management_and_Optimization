%% DINAMICA DELLA BATTERIA

function [I, P_loss, SOC_dot] = Battery_Performance(P_req, SOC, VP)

Voc = VP.V0_init + VP.dV0 * (1 - SOC);  %  Calcolo Tensione a Vuoto basata sul SOC

delta = Voc^2 - 4 * VP.R_batt * P_req;   % Calcolo della Corrente

if delta < 0  % Se la potenza richiesta supera il limite fisico della batteria

    I = VP.I_max_batt; % Saturazione
    P_loss = 1e7; % Grande penalità

else

    I = (Voc - sqrt(delta)) / (2 * VP.R_batt); % Soluzione della formula quadratica
    P_loss = VP.R_batt * I^2;

end

SOC_dot = - (I / VP.Qnom); % segno meno per la scarica


end

