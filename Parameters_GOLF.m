%% PARAMETRI VOLKSWAGEN GOLF GTE

function VP = Parameters_GOLF()

n_pass = 1; % Numero di passeggeri
pass_w = 80; % Peso passeggeri [kg]


% Meccanici

VP.m = 1624 + n_pass * pass_w; % massa [kg] + passeggero [kg]
VP.meff = VP.m * 1.07; % massa efficace [kg] + masse rotanti [kg]
VP.A = 2.10; % area veicolo [m^2]
VP.r_ruota = 0.317; % raggio ruote [m] (assumendo pneumatici standard 225/45 R17)
VP.eta_mech = 0.93; % efficienza trasmissione DSG [adim]


% Motore Termico

VP.P_max_ICE = 110000; % potenza massima ICE [W]
VP.T_max_ICE = 250; % coppia massima ICE [Nm]
VP.w_idle_ICE = 800/60*2*pi; % regime di minimo [rad/s]
VP.w_start_plateau = 1550/60*2*pi; % Inizio coppia max turbo
VP.w_end_plateau = 3500/60*2*pi; % Fine plateau
VP.w_max_ICE = 6000/60*2*pi; % pulsazione massima ICE [rad/s]
VP.T_idle = 85; % coppia a regime minimo [Nm]
VP.k_torque_ice = 0.004; % Fattore di decadimento agli alti regimi (maggiori info su pdf esplicativo)
VP.rho_fuel = 0.74; % Densità della benzina [kg/L]
VP.Q_lhv = 43.6e6; % Potere calorifico inferiore della benzina [J/kg]


% Motore Elettrico

VP.P_max_EL = 80000; % potenza massima motore elettrico [W]
VP.T_max_EL = 330; % coppia massima motore elettrico [Nm]
VP.w_cr_EL = 2300/60*2*pi; % pulsazione critica [rad/s]

% Fattori di perdita

VP.kc = 0.08; % Coefficiente Rame / Effetto Joule [W/(Nm)^2].
VP.ki = 0.15; % Coefficiente Ferro / Perdite Magnetiche [W/(rad/s)] 
VP.kw = 1e-5; % Coefficiente Ventilazione / Perdite Aerodinamiche  [W/(rad/s)^3]
VP.P_inv_standby = 200; % Consumo inverter acceso [W]


% Trasmissione (DSG 6 rapporti DQ400e)

VP.G_list = [11.55, 9.14, 6.10, 3.36, 2.67, 2.21]; % Rapporti di trasmissione
VP.Ge = 1; % EL = 1:1 ICE (P2)
VP.vel_max = 225/3.6; % velocità massima dichiarata [m/s]


% Batteria (Li-ion)

VP.E0 = 13e3; % Energia nominale [Wh]
VP.V0_init = 345; % Tensione nominale [V]
VP.Qnom = (VP.E0/VP.V0_init)*3600; % Capacità in Coulomb
VP.Chg0 = VP.E0/VP.V0_init; % Capacità batteria [Ah]
VP.P_max_batt = 100e3; % Potenza scarica max [W]
VP.I_max_batt = 300; % Corrente max [A]
VP.R_batt = 0.15; % Resistenza interna [Ohm]
VP.dV0 = -40; % variazione tensione
VP.eta_coul = 0.98; % Rendimento coulombiano [adim]


% Vincoli di protezione della batteria

VP.SOC_inf = 0.2; % Limite inferiore del valore del SOC
VP.SOC_sup = 0.9; % Limite superiore del valore del SOC


% Ambientali

VP.rho = 1.22; % densità dell'aria [kg/m^3]
VP.Cd = 0.27; % Coefficiente aerodinamico [adim]
VP.alpha = 0; % angolo pendenza [deg]
VP.g = 9.81; % accelerazione gravitazionale [m/s^2]
VP.mu_r = 0.012; % coefficiente di resistenza al rotolamento [adim]
VP.Rr = VP.mu_r*VP.m*VP.g*cosd(VP.alpha); % resistenza al rotolamento [N]
VP.Rg = VP.m*VP.g*sind(VP.alpha); % forza gravitazionale [N]
VP.Rd_factor = 0.5*VP.Cd*VP.A*VP.rho; % termine aerodinamico [adim]

VP.wf = 50; % Fattore di peso (penalità) nell'Hamiltoniana 

end