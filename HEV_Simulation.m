%% SIMULATORE DINAMICO

function Out = HEV_Simulation(lambda_init, v, VP)
N_sim = length(v);
dt = 1;

% Inizializzazione

SOC = zeros(1, N_sim);
SOC(1) = VP.SOCin;
Co_stato = zeros(1, N_sim);
Co_stato(1) = lambda_init;
E_batt = zeros(1, N_sim);
E_batt(1) = VP.E0 * VP.SOCin * 3600;

T_ICE_o = zeros(1, N_sim);
u_o = zeros(1, N_sim);
P_EL_o = zeros(1, N_sim);
P_loss_batt_o = zeros(1, N_sim);
dm_o = zeros(1, N_sim);
w_motore = zeros(1, N_sim);
P_FUEL_o = zeros(1, N_sim);


% Logica cambio (DSG a 6 rapporti)

for i = 2:N_sim
    acc = (v(i) - v(i-1)) / dt;

    if v(i) <= 15/3.6
        G = VP.G_list(1); % I marcia
    elseif v(i) <= 32/3.6
        G = VP.G_list(2); % II marcia
    elseif v(i) <= 52/3.6
        G = VP.G_list(3); % III marcia
    elseif v(i) <= 78/3.6
        G = VP.G_list(4); % IV marcia
    elseif v(i) <= 105/3.6
        G = VP.G_list(5); % V marcia
    else
        G = VP.G_list(6); % VI marcia
    end

w_avg = (v(i) / VP.r_ruota) * G * VP.Ge;
w_motore(i) = w_avg;


% Dinamica veicolo

Rd = VP.Rd_factor * (v(i)^2);
Ftr = VP.Rr + Rd + VP.Rg + VP.meff * acc;

% Limite Motore Elettrico

T_EL_limit = (w_avg < VP.w_cr_EL) * VP.T_max_EL + ...
(w_avg >= VP.w_cr_EL) * (VP.P_max_EL / (w_avg + 1e-6)); % quel valore infinitesimo aggiunto serve per evitare eventuali divisioni per 0

% Penalità

penSOC = (SOC(i-1) < VP.SOC_inf) * VP.wf - (SOC(i-1) > VP.SOC_sup) * VP.wf;

    if v(i) < 0.1 && abs(acc) < 0.01
        dm_val = 0; P_batt_netta = 200; P_loss_val = 0; T_ice_val = 0; u_val = 0;

    else

        % Generazione candidati 

        if Ftr > 0
            T_req = Ftr * VP.r_ruota / G / VP.eta_mech;
            contr_u = linspace(0, min(T_req/VP.Ge, T_EL_limit), 50);
            T_ICE_candidati = T_req - contr_u;
        else
            T_req = Ftr * VP.r_ruota / G * VP.eta_mech;
            contr_u = linspace(max(T_req/VP.Ge, -T_EL_limit), 0, 50);
            T_ICE_candidati = zeros(size(contr_u));
        end

        %  Valutazione Hamiltoniana

        dm_c = zeros(size(contr_u));
        P_netta_c = zeros(size(contr_u));
        P_loss_c = zeros(size(contr_u));

        for k = 1:length(contr_u)

            [dm_c(k), ~] = ICE_Performance(w_avg, T_ICE_candidati(k), VP); % Consumo
            [P_netta_c(k), ~] = EL_Performance(w_avg, contr_u(k), VP); % Potenza Elettrica Richiesta 
            [~, P_loss_c(k), ~] = Battery_Performance(P_netta_c(k), SOC(i-1), VP);  % Modello Batteria

        end

        P_chimica_c = P_netta_c + P_loss_c;

                                            H = dm_c + (Co_stato(i-1) + penSOC) * (P_chimica_c / VP.Q_lhv); % Hamiltoniana
                                                                [~, idx] = min(H); % Minimizzazione

        T_ice_val = T_ICE_candidati(idx);
        u_val = contr_u(idx);
        dm_val = dm_c(idx);
        P_batt_netta = P_netta_c(idx);
        P_loss_val = P_loss_c(idx);

    end

    % Aggiornamento stati

    T_ICE_o(i) = T_ice_val;
    u_o(i) = u_val;
    dm_o(i) = dm_val;
    P_EL_o(i) = P_batt_netta;
    P_loss_batt_o(i) = P_loss_val;
    P_FUEL_o(i) = dm_val * VP.Q_lhv;

    P_chimica_totale = P_batt_netta + P_loss_val;
    E_batt(i) = E_batt(i-1) - P_chimica_totale * dt;
    SOC(i) = E_batt(i) / (VP.E0 * 3600);

    % Aggiornamento Dinamico co-stato

    Voc_att = VP.V0_init + VP.dV0 * (1 - SOC(i-1)); % Recupero i valori esatti per il punto di lavoro scelto
    delta_att = Voc_att^2 - 4 * VP.R_batt * P_batt_netta;

    if delta_att > 0
   
        dVoc_dSOC = -VP.dV0;  % Calcolo della derivata parziale dI/dSOC 
    
        dI_dVoc = (1 - Voc_att / sqrt(delta_att)) / (2 * VP.R_batt); % Derivata della corrente rispetto alla tensione (dI/dVoc)

        dI_dSOC = dI_dVoc * dVoc_dSOC; % Regola della catena

    else
       
        dI_dSOC = 0; % Caso limite (saturazione)

    end

    dSOCdot_dSOC = - (1 / VP.Qnom) * dI_dSOC;  % Calcolo variazione della dinamica SOC

    dlambda_dt = - (Co_stato(i-1) + penSOC) * dSOCdot_dSOC; % Adjoint Equation

    Co_stato(i) = Co_stato(i-1) + dlambda_dt * dt; % Aggiornamento Co-stato


% Blocco di Output

Out.SOC = SOC;
Out.dm = dm_o;
Out.P_EL = P_EL_o;
Out.P_loss_batt = P_loss_batt_o;
Out.P_FUEL = P_FUEL_o;
Out.T_ice = T_ICE_o;
Out.w_ice = w_motore;
Out.T_em = u_o;
Out.t = (0:N_sim-1)*dt;
Out.Consumo_litri = trapz(dm_o) / VP.rho_fuel;
Out.distanza_km = trapz(v) / 1000;
Out.Co_stato = Co_stato;

end