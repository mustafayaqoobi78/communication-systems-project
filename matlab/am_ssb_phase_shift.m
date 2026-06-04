% AM-SSB-DSP-code
fs = 10000000;
fm = 1000;
fc = 700000;
Am = 1;  Ac = 1;
T  = 20e-3;
t  = (0:1/fs:T-1/fs).';

%% 1. Message and its Hilbert transform
m = Am*cos(2*pi*fm*t);
m_hat = Am*sin(2*pi*fm*t);

%% 2. USB modulation
I_path = m.* cos(2*pi*fc*t);
Q_path = m_hat.* sin(2*pi*fc*t);
S_usb  = I_path - Q_path;


figure('Color','w','Name','SSB modulation');
subplot(3,1,1);
plot(t*1e3,m,'LineWidth',1);
xlim([0 5]);
grid on;
ylabel('Amplitude');
title('Message m(t) - 1 kHz');

subplot(3,1,2);
plot(t*1e3,m_hat,'r','LineWidth',1);
xlim([0 5]); grid on;
ylabel('Amplitude');
title('Hilbert transform, 90 degree shifted');

subplot(3,1,3);
plot(t*1e3,S_usb);
xlim([0 0.1]);
grid on;
ylabel('Amplitude');
xlabel('Time (ms)');
title('AM-USB signal (701 kHz)');

%% 3. FFT

[f,S] = single_sided_fft(S_usb,fs);
figure('Color','w','Name','USB spectrum');
semilogy(f/1e3,S,'LineWidth',1);
xlim([698 703]);
grid on;
xlabel('Frequency (kHz)');
ylabel('Magnitude (V)');
title('Transmit spectrum - USB at 701 kHz, LSB & carrier suppressed');

usb = peak_near(f,S,fc+fm);
lsb = peak_near(f,S,fc-fm);
fprintf('\n--- AM-USB transmit spectrum ---\n');
fprintf('USB (701 kHz) = %.4g V\n', usb);
fprintf('LSB (699 kHz) = %.3e V\n', lsb);
fprintf('Sideband suppression = %.0f dB\n', 20*log10(usb/lsb));

%% 4. Coherent demod at phase = 0
LO  = cos(2*pi*fc*t);
v   = S_usb.* LO;
rec = 2*rc_lpf(v,4.23e3,fs,2);

figure('Color','w','Name','Recovery (phi=0)');
plot(t*1e3,m,'LineWidth',1.2);
hold on; plot(t*1e3,rec,'r');
xlim([10 14]);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude (V)');
legend('Original message','Recovered');
title('Input vs recovered  (\phi = 0 deg)');

%% 5. Phase-angle experiment (phase = 0, 90, 180)
% SSB property: amplitude is PRESERVED at every phase; only the output
% PHASE changes (matches report Table 1).
phis = [0 90 180];
figure('Color','w','Name','Phase experiment (SSB)');
fprintf('\n--- Phase-angle experiment (SSB) ---\n');
for k = 1:numel(phis)
    LOk  = cos(2*pi*fc*t + deg2rad(phis(k)));
    reck = 2*rc_lpf(S_usb.*LOk, 4.23e3, fs, 2);
    pk   = max(reck(t>5e-3));
    fprintf('phi = %3d deg  ->  recovered peak = %.3f V\n', phis(k), pk);
    subplot(3,1,k);
    plot(t*1e3,reck);
    xlim([10 16]);
    grid on;
    ylabel('V');
    title(sprintf('\\phi = %d deg,  peak = %.3f V', phis(k), pk));
end
xlabel('Time (ms)');

%% 6. local functions
function [f,mag] = single_sided_fft(x,fs)
    N = numel(x);
    X = fft(x)/N;
    mag = abs(X(1:floor(N/2)+1));
    mag(2:end-1) = 2*mag(2:end-1);
    f = (0:floor(N/2)).' * fs/N;
end

function a = peak_near(f,mag,f0)
[~,i] = min(abs(f-f0));
lo = max(1,i-5);
hi = min(numel(f),i+5);
a = max(mag(lo:hi));
end

function y = rc_lpf(x,fc,fs,stages)
    alpha = 2*pi*fc/fs;
    b = alpha; a = [1, -(1-alpha)]; y = x;
    for s = 1:stages, y = filter(b,a,y);
    end
end

