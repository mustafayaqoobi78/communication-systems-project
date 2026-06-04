%% Parameters
fs  = 10e6;
fc  = 700000;
Rb  = 2e3;
Tb  = 1/Rb;
sps = round(fs*Tb);

%% 1. Build the TDM stream (MULTIPLEXING)
sig1 = [0 1 0 0 0 1 0 0 0 1];
sig2 = [0 0 0 0 1 0 1 1 1 0];
tdm  = zeros(1,2*numel(sig1));
tdm(1:2:end) = sig1;
tdm(2:2:end) = sig2;
Nbits = numel(tdm);

bip = 2*tdm - 1;
m   = repelem(bip,sps).';
t   = (0:numel(m)-1).'/fs;
fprintf('TDM sequence: %s\n', mat2str(tdm));

% show the two source streams (1 kbps) and the combined TDM stream (2 kbps)
sps1 = round(fs/1e3);
t1 = (0:numel(sig1)*sps1-1).'/fs;
w1 = repelem(2*sig1-1,sps1).';
w2 = repelem(2*sig2-1,sps1).';

figure('Color','w','Name','TDM construction');

subplot(3,1,1);
plot(t1*1e3,w1,'LineWidth',1.2);
ylim([-1.5 1.5]);
grid on;
ylabel('S1');
title('Signal 1 - 1 kbps (odd slots)');

subplot(3,1,2);
plot(t1*1e3,w2,'LineWidth',1.2);
ylim([-1.5 1.5]);
grid on;
ylabel('S2');
title('Signal 2 - 1 kbps (even slots)');

subplot(3,1,3);
plot(t*1e3,m,'LineWidth',1);
ylim([-1.5 1.5]);
grid on;
ylabel('TDM');
xlabel('Time (ms)');
title('Interleaved TDM stream - 2 kbps');
exportgraphics(gcf, 'bpsk_tdm_construction.png', 'Resolution', 300)

%% ---- 2. BPSK modulation
carrier = cos(2*pi*fc*t);
s_bpsk  = m .* carrier;                 % +carrier (bit 1) / -carrier (bit 0)

bnd = find(diff(tdm)~=0,1)*Tb;          % time of first 0->1 transition (s)
figure('Color','w','Name','BPSK modulated');
subplot(2,1,1);
plot(t*1e3,s_bpsk);
xlim([0 10]);
grid on;
ylabel('Amp');
title('BPSK modulated signal (700 kHz carrier)');

subplot(2,1,2);
plot(t*1e6,s_bpsk);
grid on;
xlim(([bnd-5e-6 bnd+5e-6])*1e6);
xlabel('Time (\mus)');
ylabel('Amp');
title('Zoom at a bit boundary - 180 deg phase reversal');
exportgraphics(gcf, 'bpsk_modulated.png', 'Resolution', 300)

%% ---- 3. Transmit spectrum (sinc lobes, nulls at +/-2 kHz) --------------
[fb,Sb] = single_sided_fft(s_bpsk,fs);
figure('Color','w','Name','BPSK spectrum');

plot(fb/1e3,Sb);
xlim([696 704]);
grid on;
xlabel('Frequency (kHz)');
ylabel('Magnitude (V)');
title('BPSK spectrum - main lobe at 700 kHz, first nulls at \pm2 kHz');
exportgraphics(gcf, 'bpsk_spectrum.png', 'Resolution', 300)

%% ---- 4. Coherent demod -> LPF -> comparator -> demux  (phi = 0) --------
LO   = cos(2*pi*fc*t);
base = rc_lpf(s_bpsk.*LO, 4.8e3, fs, 1);     % product detector + 1-pole RC LPF (4.8 kHz)

centres  = round(((0:Nbits-1)+0.5)*sps);     % sample at each bit centre
samples  = base(centres);
rec_bits = double(samples(:).' > 0);     % comparator: threshold at 0 V (row, 1xNbits)
BER      = mean(rec_bits ~= tdm);

fprintf('Recovered   : %s\n', mat2str(rec_bits));
fprintf('Bit errors  : %d / %d   (BER = %.4f)\n', sum(rec_bits~=tdm), Nbits, BER);

rec_s1 = rec_bits(1:2:end);  rec_s2 = rec_bits(2:2:end);   % DEMULTIPLEX
fprintf('Signal 1 (odd) : %s   match = %d\n', mat2str(rec_s1), isequal(rec_s1,sig1));
fprintf('Signal 2 (even): %s   match = %d\n', mat2str(rec_s2), isequal(rec_s2,sig2));

figure('Color','w','Name','Recovery (phi=0)');
plot(t*1e3,m,'g','LineWidth',1.5); hold on;
plot(t*1e3,base*2,'b');                                    % scaled baseband for viewing
stairs((0:Nbits)*Tb*1e3,[rec_bits 1]*2-1,'r--','LineWidth',1.2);
xlim([0 10]); ylim([-1.6 1.6]);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude');
legend('Original TDM','Post-LPF baseband (x2)','Recovered bits','Location','best');
title(sprintf('Input vs recovered  (BER = %d/%d)', sum(rec_bits~=tdm), Nbits));
exportgraphics(gcf, 'bpsk_recovery.png', 'Resolution', 300)

%% ---- 5. Phase-angle experiment (phi = 0, 90, 180) ----------------------
% IDEAL coherent BPSK: recovered amplitude scales as cos(phi):
% FULL at 0 deg,  COLLAPSES at 90 deg,  INVERTED at 180 deg.
% This is ideal behaviour.

phis = [0 90 180];
figure('Color','w','Name','Phase experiment (BPSK)');
fprintf('\n--- Phase-angle experiment (BPSK, post-LPF amplitude) ---\n');
for k = 1:numel(phis)
    LOk = cos(2*pi*fc*t + deg2rad(phis(k)));
    bk  = rc_lpf(s_bpsk.*LOk, 4.8e3, fs, 1);
    pk  = max(abs(bk(sps:end)));
    fprintf('phi = %3d deg  ->  peak |baseband| = %.3f V\n', phis(k), pk);
    subplot(3,1,k);
    plot(t*1e3,bk);
    xlim([0 10]);
    grid on;
    ylabel('V');
    title(sprintf('\\phi = %d deg,  peak = %.3f V', phis(k), pk));
end
xlabel('Time (ms)');
exportgraphics(gcf, 'bpsk_phase.png', 'Resolution', 300)

%% ======================= local functions ================================
function [f,mag] = single_sided_fft(x,fs)
    N = numel(x);
    X = fft(x)/N;
    mag = abs(X(1:floor(N/2)+1));
    mag(2:end-1) = 2*mag(2:end-1);
    f = (0:floor(N/2)).' * fs/N;
end

function y = rc_lpf(x,fc,fs,stages)
    % Cascaded one-pole RC low-pass using base-MATLAB filter().
    alpha = 2*pi*fc/fs;
    b = alpha;
    a = [1, -(1-alpha)];
    y = x;
    for s = 1:stages, y = filter(b,a,y);

    end
end
