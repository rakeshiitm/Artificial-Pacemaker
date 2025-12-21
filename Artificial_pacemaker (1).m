% Artificial Pacemaker Simulation

clc; clear; close all;

% Sampling frequency
fs = 360;               % 360 samples per second (like real ECG data)
t = (0:1/fs:20)';          % 20-second time vector

% Create a simple ECG-like signal
hr = 60;                % Heart rate (60 beats per minute)
ecg = 0.6*sin(2*pi*(hr/60)*t) + 0.5*randn(size(t)); % base + noise (randn is mostly in the range of (+-3) ) 

% 1. Bandpass filter (Butterworth)

[b,a] = butter(2, [5 15]/(fs/2), 'bandpass');  
% using butterworth function (which takes normalized freq. as input and "bandpass"
% allows only that certain range of freq),   to calc the 2 constants a,b used for filtering 
filt_ecg = filtfilt(b, a, ecg); % zero-phase filtering ( by using normal filter func phase shift occurs
%  so we use filtfilt to ensure zero-phase change , better filtering


% 2. Derivative filter
d_ecg = filter([1 2 0 -2 -1]/8, 1, filt_ecg); % y(x)= [x(n+2)+2x(n+1) -2x(n-1)-x(n-2)]/8 (5-point central differentiation approx. ) 
% to point out the spikes , which eases the detection of heartbeats. 

% 3. Squaring
sq_ecg = d_ecg.^2;

% 4. Moving window integration (150 ms)
win_size = round(0.15*fs);
mov_int = filter(ones(1, win_size)/win_size, 1, sq_ecg);

ecg_data = [t d_ecg];

% 5. Adaptive thresholding for R-peak detection
thr = mean(mov_int)*1.5;
r_peaks = mov_int > thr;

% 6. Pacemaker logic
T_escape = 1.0; % 1 second = 60 bpm lower rate
T_refrac = 0.25; % 250 ms refractory 
T_pulse  = 0.002; % pacing pulse duration (2 ms)
time_since_beat = 0;
pace_pulse = zeros(size(t));
tic


num_of_times_paced=0;
for i = 2:length(t)
    dt = 1/fs;
    time_since_beat = time_since_beat + dt;

    % If a natural beat detected
    if r_peaks(i) && time_since_beat > T_refrac
        time_since_beat = 0;
        %pace_pulse(i:i+round(T_pulse*fs)) = 1;
    end

    % If no beat detected within escape time → generate pacing pulse
    if time_since_beat >= T_escape
        pace_pulse(i:i+round(T_pulse*fs)) = 1;
        num_of_times_paced=num_of_times_paced+1;
        time_since_beat = 0;
    end
end
toc

% 7. Plot results
figure;

subplot(5,1,1);
plot(t, ecg); title('Raw ECG');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(5,1,2);
plot(t, filt_ecg);
title('ECG after butterworth filter');
xlabel('Time (s)');
 
subplot(5,1,3);
plot(t, d_ecg);
title('ECG after derivative filter');
xlabel('Time (s)');
 
subplot(5,1,4);
plot(t, mov_int); hold on;
yline(thr, 'r--'); 
title('Filtered ECG with Threshold');
xlabel('Time (s)');

subplot(5,1,5);
plot(t, pace_pulse, 'LineWidth', 1.2);
title('Pacemaker Output');
xlabel('Time (s)'); ylabel('Pulse');



fprintf("Number of times Pacemaker did its work = %d ",num_of_times_paced)
