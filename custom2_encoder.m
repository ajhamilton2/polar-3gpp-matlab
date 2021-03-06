function f = custom2_encoder(a, E)
% CUSTOM2_ENCODER Customised polar encoder.
%   f = CUSTOM2_ENCODER(a, E) encodes the information bit sequence a, in 
%   order to obtain the encoded bit sequence f.
%
%   a should be a binary row vector comprising A number of bits, each 
%   having the value 0 or 1. 
%
%   E should be an integer scalar. It specifies the number of bits in the
%   encoded bit sequence, where E should be greater than A.
%
%   f will be a binary row vector comprising E number of bits, each having
%   the value 0 or 1.
%
%   See also CUSTOM2_DECODER
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

A = length(a);

% The CRC polynomial used in 3GPP PBCH and PDCCH channel is
% D^24 + D^23 + D^21 + D^20 + D^17 + D^15 + D^13 + D^12 + D^8 + D^4 + D^2 + D + 1
%crc_polynomial_pattern = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];
%P = length(crc_polynomial_pattern)-1;

% Determine the number of information and CRC bits (if any).
K = A; % Required for polar_encoder
%K = A+P; % Required for CA_polar_encoder, DCA_polar_encoder

% Determine the number of bits used at the input and output of the polar
% encoder kernal.
N = get_3GPP_N(K,E,9); % n_max = 9 is used in PBCH and PDCCH channels
% N = get_3GPP_N(K,E,10); % n_max = 10 is used in PUCCH channels
% N = get_3GPP_N(K,E,inf); % Not generally compatible with get_3GPP_sequence_pattern
% N = 2^ceil(log2(E)); % Required for BIVS, BIVP, NATS or NATP rate matching

% Get a CRC interleaver pattern.
% crc_interleaver_pattern = get_3GPP_crc_interleaver_pattern(K);

% Get a rate matching pattern.
[rate_matching_pattern, mode] = get_3GPP_rate_matching_pattern(K,N,E);
% [rate_matching_pattern, mode] = get_BIVS_rate_matching_pattern(N,E);
% [rate_matching_pattern, mode] = get_BIVP_rate_matching_pattern(N,E);
% [rate_matching_pattern, mode] = get_NATS_rate_matching_pattern(N,E);
% [rate_matching_pattern, mode] = get_NATP_rate_matching_pattern(N,E);

% Get a sequence pattern.
Q_N = get_3GPP_sequence_pattern(N);
% Q_N = get_PW_sequence_pattern(N);

% Get an information bit pattern.
info_bit_pattern = get_3GPP_info_bit_pattern(K, Q_N, rate_matching_pattern, mode);
% info_bit_pattern = get_info_bit_pattern(K, Q_N, rate_matching_pattern);

% Perform polar encoding.
e = polar_encoder(a,info_bit_pattern,rate_matching_pattern);
% e = CA_polar_encoder(a,crc_polynomial_pattern,info_bit_pattern,rate_matching_pattern);
% e = DCA_polar_encoder(a,crc_polynomial_pattern,crc_interleaver_pattern,info_bit_pattern,rate_matching_pattern);

% Perform channel interleaving.
% channel_interleaver_pattern = get_3GPP_channel_interleaver_pattern(E);
% f = e(channel_interleaver_pattern);
f = e;