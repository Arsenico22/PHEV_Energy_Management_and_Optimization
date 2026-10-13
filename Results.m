function Results(Out, v, VP, lambda_ottimo, v1, v2, v3)

t = (0:length(v)-1)';  


%% RISULTATI FINALI E CONSUMI

fprintf('RISULTATI OTTIMIZZAZIONE: \n\n');
fprintf('Lambda iniziale ottimale trovato: %.6f\n', lambda_ottimo);
fprintf('SOC Finale Ottenuto: %.6f (Target: %.2f)\n', Out.SOC(end), VP.SOC_target);
fprintf('Errore di convergenza: %.6f\n', abs(Out.SOC(end) - VP.SOC_target));

distanza_km = Out.distanza_km;
fprintf('\n\nCONSUMI E PRESTAZIONI: \n\n');
fprintf('Durata totale del ciclo: %.2f minuti\n', t(end)/60);
fprintf('Velocità massima: %.2f km/h\n', max(v)*3.6);
fprintf('Distanza totale percorsa: %.2f km\n', distanza_km);
fprintf('Carburante consumato: %.2f litri\n', Out.Consumo_litri);
fprintf('Consumo medio: %.2f km/l\n', distanza_km / Out.Consumo_litri);


% Confronto Solo ICE (uso lambda molto alto per simulare l'assenza di batteria)

Out_ICE = HEV_Simulation(1000, v, VP);
risparmio = Out_ICE.Consumo_litri - Out.Consumo_litri;
fprintf('\n\nCONFRONTO SOLO TERMICO: \n\n');
fprintf('Consumo Solo ICE: %.2f litri\n', Out_ICE.Consumo_litri);
fprintf('Risparmio Carburante: %.2f litri (%.1f%%)\n', risparmio, (risparmio/Out_ICE.Consumo_litri)*100);


%% GRAFICO SOC vs CO-STATO 

figure;
hold on;
grid on;

yyaxis left
plot(t/60, Out.SOC * 100, 'g');
ylabel('SOC [%]');
ylim([0, 100]); 
ax = gca;
ax.YColor = 'g'; 

yyaxis right
plot(t/60, Out.Co_stato, 'b');
ylabel('Co-stato lambda');
ylim([min(Out.Co_stato) - 0.25, max(Out.Co_stato) + 0.25]); 
ax.YColor = 'b'; 


title('SOC e Co-stato ottimi');
xlabel('Tempo [min]');
legend('SoC [%]', '\lambda (Co-stato)');

hold off;


%% ANALISI ENERGETICA

P_el_istantanea = Out.P_EL; 
P_recupero = zeros(size(P_el_istantanea));
idx_regen = P_el_istantanea < -0.1;
P_recupero(idx_regen) = P_el_istantanea(idx_regen);
Lavoro_recuperato_kWh = abs(cumtrapz(t, P_recupero)) / 3.6e6; 

P_tot_erogata = max(0, Out.P_FUEL*0.35 + Out.P_EL); % Approssimazione potenza totale alle ruote
Lavoro_erogato_kWh = cumtrapz(t, P_tot_erogata) / 3.6e6;

figure;

% Potenza Termica
subplot(3,1,1);
plot(t/60, Out.P_FUEL/1000, 'r', 'LineWidth', 1);
ylabel('P_{Term} [kW]'); 
title('Analisi Dinamica dei Flussi Energetici'); 
grid on; xlim([0 t(end)/60]);

% Potenza Elettrica
subplot(3,1,2);
plot(t/60, P_el_istantanea/1000, 'g', 'LineWidth', 1);
hold on;
yline(0, 'k--', 'HandleVisibility', 'off'); % Linea per distinguere trazione e recupero
ylabel('P_{Ele} [kW]'); 
grid on; xlim([0 t(end)/60]);
legend('Trazione / Recupero', 'Location', 'northeast');

% Energie Cumulate 
subplot(3,1,3);
plot(t/60, Lavoro_erogato_kWh, 'r', 'LineWidth', 1.5, 'DisplayName', 'Energia Erogata');
hold on;
plot(t/60, Lavoro_recuperato_kWh, 'g', 'LineWidth', 1.5, 'DisplayName', 'Energia Recuperata');
ylabel('Energia [kWh]'); 
xlabel('Tempo [min]'); 
grid on; xlim([0 t(end)/60]);
legend('show', 'Location', 'northwest');


%% CONFRONTO VALORI CO-STATO

Vett_Lambda_Test = lambda_ottimo-0.5 : 0.125 : lambda_ottimo+0.5; % 8 valori equidistanti intorno al lambda ottimo
colori = jet(length(Vett_Lambda_Test));

figure;
hold on;

for i = 1:length(Vett_Lambda_Test)
    Out_Test = HEV_Simulation(Vett_Lambda_Test(i), v, VP);
    plot(t/60, Out_Test.SOC, 'Color', colori(i,:),  'DisplayName', ['\lambda = ', num2str(Vett_Lambda_Test(i), '%.2f')]);
end
yline(VP.SOC_target, '--k', 'DisplayName', 'Target SOC ');
xlabel('Tempo [minuti]');
ylabel('SOC');
ylim ([0 1]);
title('Ricerca del lambda ottimale');
legend('show');
grid on;
box on;


%% ISTOGRAMMA CONSUMI

figure;
bar([Out.Consumo_litri, Out_ICE.Consumo_litri], 'r');
set(gca, 'xticklabel', {'Ibrido ottimizzato', 'Solo ICE'});
ylabel('Litri consumati'); 
title('Confronto Consumi'); 
grid on;


%% MAPPA DI EFFICIENZA ICE

w_grid_rpm = linspace(500, 6500, 200);
t_grid_nm = linspace(0, 300, 200);
[W_grid_rpm, T_grid_nm] = meshgrid(w_grid_rpm, t_grid_nm);
eta_map = zeros(size(W_grid_rpm));

for r = 1:size(W_grid_rpm,1)
    for c = 1:size(W_grid_rpm,2)
        w_curr = W_grid_rpm(r,c) * pi / 30;
        T_curr = T_grid_nm(r,c);
        [~, eta_val] = ICE_Performance(w_curr, T_curr, VP);

        if w_curr < VP.w_idle_ICE || w_curr > VP.w_max_ICE
            T_max_curr = 0;
        elseif w_curr < VP.w_start_plateau
            T_max_curr = VP.T_idle + (VP.T_max_ICE - VP.T_idle) * (w_curr - VP.w_idle_ICE) / (VP.w_start_plateau - VP.w_idle_ICE);
        elseif w_curr <= VP.w_end_plateau
            T_max_curr = VP.T_max_ICE;
        else
            T_max_curr = VP.T_max_ICE - VP.k_torque_ice * (w_curr - VP.w_end_plateau)^2;
        end

        if T_curr > T_max_curr || T_curr < 0
            eta_map(r,c) = NaN;
        else
            eta_map(r,c) = eta_val;
        end
    end
end

figure;
ax = axes;
set(ax, 'Color', [0 0 0.6]);
hold on;

contourf(W_grid_rpm, T_grid_nm, eta_map, 20, 'LineStyle', 'none', 'HandleVisibility', 'off');
colormap(ax, jet);
h_cb = colorbar; ylabel(h_cb, 'Efficienza Termica');

[C, h_lev] = contour(W_grid_rpm, T_grid_nm, eta_map, [0.15 0.25 0.32 0.35 0.37], 'k', 'HandleVisibility', 'off');
clabel(C, h_lev, 'FontSize', 8, 'Color', 'k');

w_lim_rad = linspace(VP.w_idle_ICE, VP.w_max_ICE, 150);
T_lim_plot = zeros(size(w_lim_rad));
for k = 1:length(w_lim_rad)
    w_c = w_lim_rad(k);
    if w_c < VP.w_start_plateau
        T_lim_plot(k) = VP.T_idle + (VP.T_max_ICE - VP.T_idle) * (w_c - VP.w_idle_ICE) / (VP.w_start_plateau - VP.w_idle_ICE);
    elseif w_c <= VP.w_end_plateau
        T_lim_plot(k) = VP.T_max_ICE;
    else
        T_lim_plot(k) = VP.T_max_ICE - VP.k_torque_ice * (w_c - VP.w_end_plateau)^2;
    end
end
plot(w_lim_rad * 30 / pi, T_lim_plot, 'black', 'LineWidth', 3, 'DisplayName', 'Limite Coppia Motore');

w_rpm_real = Out.w_ice * 30 / pi;
idx_on = Out.dm > 1e-4;
s = scatter(w_rpm_real(idx_on), Out.T_ice(idx_on), 8, 'k', 'filled', 'HandleVisibility', 'off');
s.MarkerFaceAlpha = 0.2;

grid on; box on;
set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.4);
xlabel('Regime Motore [rpm]'); ylabel('Coppia Motore [Nm]');
title(' Mappa ICE 1.4 TSI' );
xlim([500 6200]); ylim([0 300]);

legend('Location', 'northeast');


%% MAPPA DI EFFICIENZA MOTORE ELETTRICO

w_rad_grid = linspace(0, 1400, 200);
t_grid = linspace(-VP.T_max_EL, VP.T_max_EL, 200);
[W_RAD, T_EM_grid] = meshgrid(w_rad_grid, t_grid);

eta_em_map = zeros(size(W_RAD));

for r = 1:size(W_RAD, 1)

    for c = 1:size(W_RAD, 2)

        w_curr = W_RAD(r,c);
        T_curr = T_EM_grid(r,c);
        T_lim_curr = min(VP.T_max_EL, VP.P_max_EL / (w_curr + 1e-6));  % calcolo del limite di coppia fisico (T_max = P_max / w)
       
        if abs(T_curr) > T_lim_curr
            eta_em_map(r,c) = NaN;  % fuori dai limiti la mappa non è definita
        else
            
            [~, eta_val] = EL_Performance(w_curr, T_curr, VP);
            eta_em_map(r,c) = eta_val;
        end
    end
end


W_RPM_plot = W_RAD * 60 / (2*pi); % Conversione asse X in RPM

figure;

ax_em = axes;
set(ax_em, 'Color', [0 0 0.6]); 
hold on;
contourf(W_RPM_plot, T_EM_grid, eta_em_map, 30, 'LineStyle', 'none');
colormap(ax_em, jet);
h_cb = colorbar;
ylabel(h_cb, 'Efficienza \eta_{em}');

[C, h_lev] = contour(W_RPM_plot, T_EM_grid, eta_em_map, [0.80, 0.85, 0.9, 0.92, 0.94, 0.96], 'k'); % Curve di livello interne
clabel(C, h_lev, 'FontSize', 8);

w_lim_rad = linspace(0, 1400, 100);
w_lim_rpm = w_lim_rad * 60 / (2*pi);
T_lim_pos = min(VP.T_max_EL, VP.P_max_EL ./ (w_lim_rad + 1e-6));
plot(w_lim_rpm, T_lim_pos, 'k', 'LineWidth', 2.5);
plot(w_lim_rpm, -T_lim_pos, 'k', 'LineWidth', 2.5);

idx_active = abs(Out.T_em) > 0.1;
scatter(Out.w_ice(idx_active) * 60 / (2*pi), Out.T_em(idx_active), 6, 'k', 'filled', 'MarkerFaceAlpha', 0.3); % Sovrapposizione Punti di Lavoro PMP

grid on;
xlabel('Regime Motore Elettrico [rpm]');
ylabel('Coppia T [Nm]');
title('Punti di Lavoro su Mappa Efficienza Reale');


%% PERCORSO CICLO COMBINATO

figure;
plot(t/60, v * 3.6, 'm');
grid on; hold on;

m1 = length(v1)/60;
m2 = (length(v1) + length(v2))/60;
m3 = (length(v1) + length(v2) + length(v3))/60;

xline(m1, '--k', 'Low');
xline(m2, '--k', 'Medium');
xline(m3, '--k', 'High');

xlabel('Tempo [minuti]');
ylabel('Velocità [km/h]');
title('Ciclo WLTC Completo');