%% ALGORITMO DI BISEZIONE

function [lambda_ottimale, SOC_finale] = Bisection(L_inf, L_sup, v, VP)

max_iter = 15;

for i = 1:max_iter
    lambda_test = (L_inf + L_sup) / 2;
    Out = HEV_Simulation(lambda_test, v, VP);
    SOC_finale = Out.SOC(end);

    if SOC_finale < VP.SOC_target

        L_inf = lambda_test;
    else

        L_sup = lambda_test;
    end
end
lambda_ottimale = lambda_test;


end