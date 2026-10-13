%% -------------------------------------------GESTIONE ENERGETICA DI UN VEICOLO IBRIDO MEDIANTE PMP-------------------------------------------------------------

clear;
clc;
close all;

%% CARICAMENTO PARAMETRI VETTURA

VP = Parameters_GOLF();


%% -------------------------------------------------------- SELEZIONARE MODALITA' TEST --------------------------------------------------

% 'CS' (Scenario Charge Sustaining);
% 'CD' (Scenario Charge Depleting)

                                                                 test_mode = 'CS';
switch test_mode

    case 'CS'
        VP.SOCin = 0.6;
        VP.SOC_target = 0.6;

    case 'CD'
        VP.SOCin = 0.8;
        VP.SOC_target = 0.4;

end

%% GESTIONE CICLI DI GUIDA

load('cycles_wltc.mat'); % estrazione cicli di guida

v1 = WLTC_class_1.Data / 3.6;
v2 = WLTC_class_2.Data / 3.6;
v3 = WLTC_class_3a.Data / 3.6;

v = [v1(:); v2(:); v3(:)]; % creazione di un ciclo misto WLTC FULL 1 + 2 + 3a (dall'urbano all'autostradale)

t = (0:length(v)-1)'; % asse temporale


%% OTTIMIZZAZIONE MEDIANTE BISEZIONE

L_inf = 2;
L_sup = 8;

[lambda_ottimo, ~] = Bisection(L_inf, L_sup, v, VP);


%% SIMULAZIONE

Out = HEV_Simulation(lambda_ottimo, v, VP);


%% GRAFICI E RISULTATI

Results(Out, v, VP, lambda_ottimo, v1, v2, v3);

