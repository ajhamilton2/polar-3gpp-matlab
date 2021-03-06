function a_hat = PUCCH_decoder(f_tilde, A, L, min_sum)
% PUCCH_DECODER Physical Uplink Control Channel (PUCCH) polar decoder from 3GPP New
% Radio, as specified in Section 6.3.1 of TS 38.212 v1.1.1
%   a_hat = PUCCH_DECODER(f_tilde, A, L, min_sum) decodes the encoded LLR sequence 
%   f_tilde, in order to obtain the recovered information bit sequence 
%   a_hat.
%
%   f_tilde should be a real row vector comprising E number of Logarithmic
%   Likelihood Ratios (LLRS), each having a value obtained as LLR =
%   ln(P(bit=0)/P(bit=1)).
%
%   A should be an integer scalar. It specifies the number of bits in the
%   information bit sequence, where A should be less than E.
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
%   a_hat will be a binary row vector comprising A number of bits, each 
%   having the value 0 or 1.
%
%   See also PUCCH_ENCODER
%
% Copyright � 2017 Robert G. Maunder. This program is free software: you 
% can redistribute it and/or modify it under the terms of the GNU General 
% Public License as published by the Free Software Foundation, either 
% version 3 of the License, or (at your option) any later version. This 
% program is distributed in the hope that it will be useful, but WITHOUT 
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
% more details.

addpath 'components'

E = length(f_tilde);

% NEED TO ADD SEGMENTATION

% NEED TO CONFIRM CRC

% The CRC polynomial used in 3GPP PUCCH channel is
% D^11 + D^10 + D^9 + D^5 + 1
crc_polynomial_pattern = [1 1 1 0 0 0 1 0 0 0 0 1];

% The CRC has P bits. P-min(P2,log2(L)) of these are used for error
% detection, where L is the list size. Meanwhile, min(P2,log2(L)) of
% them are used to improve error correction. So the CRC needs to be
% min(P2,log2(L)) number of bits longer than CRCs used in other codes,
% in order to achieve the same error detection capability.
P = length(crc_polynomial_pattern)-1;
P2 = 3;

% Determine the number of information and CRC bits.
K = A+P;

if K-3 < 12
    error('polar_3gpp_matlab:UnsupportedBlockLength','K-3 should be no less than 12.');
end

% Determine the number of bits used at the input and output of the polar
% encoder kernal.
N = get_3GPP_N(K,E,10); % n_max = 10 is used in PUCCH channels

% Get a rate matching pattern.
[rate_matching_pattern, mode] = get_3GPP_rate_matching_pattern(K,N,E);

% Get a sequence pattern.
Q_N = get_3GPP_sequence_pattern(N);

% Perform channel deinterleaving
channel_interleaver_pattern = get_3GPP_channel_interleaver_pattern(E);
e_tilde = zeros(1,E);
e_tilde(channel_interleaver_pattern) = f_tilde;

if K - 3 <= 22
    % Use PC-polar
    n_PC = 3;

    % Get an information bit pattern.
    info_bit_pattern = get_3GPP_info_bit_pattern(K+n_PC, Q_N, rate_matching_pattern, mode);

    % Get a PC bit pattern.
    if E-K+3 > 192
        PC_bit_pattern = get_PC_bit_pattern(info_bit_pattern, Q_N, n_PC, 1);
    else        
        PC_bit_pattern = get_PC_bit_pattern(info_bit_pattern, Q_N, n_PC, 0);
    end
    
    % Perform polar decoding.
    a_hat = PCCA_polar_decoder(e_tilde,crc_polynomial_pattern,info_bit_pattern,PC_bit_pattern,5,rate_matching_pattern,mode,L,min_sum,P2);
else
    % Use CA-polar
    
    % Get an information bit pattern.
    info_bit_pattern = get_3GPP_info_bit_pattern(K, Q_N, rate_matching_pattern, mode);
    % Perform polar decoding.
    a_hat = CA_polar_decoder(e_tilde,crc_polynomial_pattern,info_bit_pattern,rate_matching_pattern,mode,L,min_sum,P2);
end   

% SEGMENTATION