🏗️ Vehicle Architecture

The system adopts a P2 parallel hybrid architecture, where the electric motor is integrated directly between the ICE and the 6-speed dual-clutch transmission (DSG). This configuration allows for the complete decoupling of the thermal engine for pure electric driving or the synergistic cooperation of both power units.

📂 Project Structure

The code is organized modularly to separate the physical component modeling from the optimization algorithm:

Main.m

Script manages data loading, operating mode selection, calls the bisection algorithm, and coordinates temporal integration


Parameters_GOLF.m
Vehicle Database:
Contains physical parameters of the VW Golf GTE: masses, aerodynamic coefficients, torque maps, transmission efficiencies, and battery parameters.


HEV_Simulation.m
Model Core:
Quasi-static dynamic simulator. Solves the Hamiltonian instant by instant to determine the optimal power split.

Bisection.m
Optimization Algorithm:
Iterative search for the initial co-state (λ) to ensure the final battery state of charge (SOC) target is met. 

ICE_Performance.m
Thermal Model:
Calculates instantaneous fuel consumption based on engine speed and requested torque, including turbocharger limits.

EL_Performance.m
Electric Model:
Models energy losses (copper, iron, mechanical, and auxiliary) for the inverter and electric motor.

Battery_Performance.m
Electrochemical Model:
Equivalent circuit battery dynamics, calculation of open-circuit voltage varying with SOC, and Joule heating losses.

Results.m
Post-Processing:
Processes raw data, calculates average fuel consumption (km/l), and generates comparison plots.


📊 Control Methodology (PMP)
The global optimization problem is transformed into an instantaneous minimization of the Hamiltonian function:

 H(SOC(t),u(t),λ(t),t) = m_f(u(t),t) + (λ(t)+ w(SOC)) ⋅ P_ec (u(t),t)

The co-state (λ) acts as the dynamic price of electric energy and is calibrated via a bisection (shooting method) algorithm to converge precisely onto the target final charge state.

📈 Main Results

System performance was validated over a mixed WLTC (Class 1+2+3a) driving cycle:

Charge Sustaining (CS) Mode
Objective: Maintain a constant battery state of charge (SOC_init ≈ SOC_final = 60% )
Fuel Savings: 30.2% compared to a purely thermal propulsion system.

Charge Depleting (CD) Mode
Objective: Utilize battery energy starting from full charge (80%) down to the programmed minimum limit (40%). Equivalent Average Consumption: 93.34 km/l with a fuel savings of 85.9%.
