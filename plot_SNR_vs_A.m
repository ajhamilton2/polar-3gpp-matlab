function plot_SNR_vs_A(code, A, R, L, min_sum, target_block_errors, target_BLER, EsN0_start, EsN0_delta, seed)
% PLOT_SNR_VS_A Plots Signal to Noise Ratio (SNR) required to achieve a 
% particular Block Error Rate (BLER) as a function of block length, for 
% polar codes.
%   plot_SNR_vs_A(code, A, R, L, min_sum, target_block_errors, target_BLER, EsN0_start, EsN0_delta, seed)
%   generates the plots.
%
%   code should be a string. This identifies which encoder and decoder
%   functions to call. For example, if code is 'custom1', then the
%   functions custom1_encoder and custom1_decoder will be called. The
%   encoder function should have a format f = custom1_encoder(a, E). The
%   decoder function should have a format
%   a_hat = custom1_decoder(f_tilde, A, L, min_sum). Refer to these
%   functions for explanations of their inputs and outputs. Suitable values
%   for code include 'custom1' and 'PBCH'.
%
%   A should be an integer row vector. Each element specifies the number of 
%   bits in each set of simulated information bit sequences, before CRC and 
%   other redundant bits are included.
%
%   R should be an real row vector. Each element of R specifies one 
%   coding rate R=A/E to simulate, where E is the number of bits in each 
%   encoded bit sequence.
%
%   L should be a scalar integer. It specifies the list size to use during
%   Successive Cancellation List (SCL) decoding.
%
%   min_sum shoular be a scalar logical. If it is true, then the SCL
%   decoding process will be completed using the min-sum approximation.
%   Otherwise, the log-sum-product will be used. The log-sum-product gives
%   better error correction capability than the min-sum, but it has higher
%   complexity.
%
%   target_block_errors should be an integer scalar. The simulation of each
%   SNR for each coding rate will continue until this number of block
%   errors have been observed. A value of 100 is sufficient to obtain
%   smooth BLER plots for most values of A. Higher values will give
%   smoother plots, at the cost of requiring longer simulations.
%
%   target_BLER should be a real scalar, in the range (0, 1). The
%   simulation of each coding rate will continue until the BLER plot
%   reaches this value.
%
%   EsN0_start should be a real row vector, having the same length as the
%   vector of coding rates. Each value specifies the Es/N0 SNR to begin at
%   for the simulation of the corresponding coding rate.
%
%   EsN0_delta should be a real scalar, having a value greater than 0.
%   The Es/N0 SNR is incremented by this amount whenever
%   target_block_errors number of block errors has been observed for the
%   previous SNR. This continues until the BLER reaches target_BLER.
%
%   seed should be an integer scalar. This value is used to seed the random
%   number generator, allowing identical results to be reproduced by using
%   the same seed. When running parallel instances of this simulation,
%   different seeds should be used for each instance, in order to collect
%   different results that can be aggregated together.
%
%   See also CUSTOM1_ENCODER and CUSTOM1_DECODER
%
% Copyright � 2017 Robert G. Maunder. This program is free software: you 
% can redistribute it and/or modify it under the terms of the GNU General 
% Public License as published by the Free Software Foundation, either 
% version 3 of the License, or (at your option) any later version. This 
% program is distributed in the hope that it will be useful, but WITHOUT 
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
% more details.

% Default values
if nargin == 0
    code = 'custom1';
    A = 16:16:1024;
    R = [0.8333 0.7500 0.6666 0.5000 0.4000 0.3333 0.2500 0.2000 0.1666 0.1250];
    L = 1;
    min_sum = true;
    target_block_errors = 10;
    target_BLER = 1e-1;
    EsN0_start = [-1, -2, -3, -4, -5, -6, -7, -8, -9, -10];
    EsN0_delta = 0.5;
    seed = 0;
end

% Seed the random number generator
rng(seed);

% Create a figure to plot the results.
figure
axes1 = axes;
title([code, ' polar code, L = ',num2str(L),', QPSK, AWGN']);
ylabel(['E_s/N_0 [dB] at BLER = ',num2str(target_BLER)]);
xlabel('A');
xlim([0,max(A)]);
grid on
hold on
drawnow

% Consider each coding rate in turn
for R_index = 1:length(R)
    
    % Create the plot
    plots(R_index) = plot(nan,'Parent',axes1);
    set(plots(R_index),'XData',A);
    legend(cellstr(num2str(R(1:R_index)', 'A/E=%0.3f')),'Location','eastoutside');
    
    EsN0s = nan(1,length(A));
    
    % Consider each information block length in turn
    for A_index = 1:length(A)
        E = round(A(A_index)/R(R_index));
        
        % Skip any combinations of block lengths that are not supported
        try
            % Initialise the BLER and SNR
            BLER=1;
            prev_BLER = nan;
            EsN0 = EsN0_start(R_index);
            prev_EsN0 = nan;
            
            % Loop over the SNRs
            while BLER > target_BLER
                % Convert from SNR (in dB) to noise power spectral density
                N0 = 1/(10^(EsN0/10));
                
                % Start new counters
                block_error_count = 0;
                block_count = 0;
                
                % Continue the simulation until enough block errors have been simulated
                while block_error_count < target_block_errors
                    
                    % Generate a random frame of bits
                    a = round(rand(1,A(A_index)));
                    
                    % Perform polar encoding
                    f = feval([code,'_encoder'], a, E);
                    
                    % QPSK modulation
                    f2 = [f,zeros(1,mod(-length(f),2))];
                    tx = sqrt(1/2)*(2*f2(1:2:end)-1)+1i*sqrt(1/2)*(2*f2(2:2:end)-1);
                    
                    % Simulate transmission
                    rx = tx + sqrt(N0/2)*(randn(size(tx))+1i*randn(size(tx)));
                    
                    % QPSK demodulation
                    f2_tilde = zeros(size(f2));
                    f2_tilde(1:2:end) = -4*sqrt(1/2)*real(rx)/N0;
                    f2_tilde(2:2:end) = -4*sqrt(1/2)*imag(rx)/N0;
                    f_tilde = f2_tilde(1:length(f));
                    
                    % Perform polar decoding
                    a_hat = feval([code, '_decoder'],f_tilde,A(A_index),L,min_sum);
                    
                    % Determine if we have a block error
                    if ~isequal(a, a_hat)
                        block_error_count = block_error_count+1;
                    end
                    
                    % Accumulate the number of blocks that have been simulated 
                    % so far
                    block_count = block_count+1;
                end
                prev_BLER = BLER;
                BLER = block_error_count/block_count;
                prev_EsN0 = EsN0;
                EsN0 = EsN0 + EsN0_delta;
            end
        catch ME
            if strcmp(ME.identifier, 'polar_3gpp_matlab:UnsupportedBlockLength')
                warning('polar_3gpp_matlab:UnsupportedBlockLength','%s does not support the combination of block lengths A=%d and E=%d. %s',code,A(A_index),E, getReport(ME, 'basic', 'hyperlinks', 'on' ));
                continue
            else
                rethrow(ME);
            end
        end
        % Use interpolation to determine the SNR where the BLER equals the target
        EsN0s(A_index) = interp1(log10([prev_BLER, BLER]),[prev_EsN0,EsN0],log10(target_BLER));

        % Plot the SNR vs A results
        set(plots(R_index),'YData',EsN0s);
        drawnow;
    end
end
