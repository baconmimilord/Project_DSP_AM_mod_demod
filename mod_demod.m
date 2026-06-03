close all, clear all;
%% tin hieu ban tin m(t) (doan audio thu san)
[m_raw,fs_raw] = audioread("audio_file.wav");
m_raw = m_raw'; %chuyen m thanh vector hang
m_raw_len = length(m_raw);

%de dieu che tin hieu voi song mang tan so 75000 can tang toc do lay mau
%cua tin hieu len > 150kHz -> thuc hien chen diem khong voi he so
%upsampling L = 4
L = 4;
fs = fs_raw * L;
m = interp(m_raw,L,2,1/2);

%% B1: dieu che tin hieu DSB-SC AM
m_len = length(m);
t = [0 : m_len - 1]/fs; %tao truc thoi gian cho ban tin sau upsample
fc = 75000;     %tan so song mang
Ac = 1;         %bien do song mang
%tin hieu song mang
c = Ac * cos(2*pi*fc*t);
%tin hieu dieu che
s = m .* c;

%% B2: tao nhieu cho kenh truyen
SNR = 10;
r = awgn(s, SNR, 'measured'); %tin hieu tai may thu

%% B3: Giai dieu che tin hieu
%su dung bo tron tan de thu tin hieu baseband
mixer_out = r .* cos(2*pi*fc*t);
%thiet ke bo loc thong thap de thu tin hieu baseband
f_cut = 3500;
[b, a] = butter(5, f_cut/(fs/2), 'low');
r_filtered = 2 * filter(b,a,mixer_out);
%sound(r_filtered,fs);

%% B4: Loc nhieu Gauss trang
% uoc luong va loai bo nhieu bang phuong phap tru pho
% thuc hien chia r(t) thanh frame keo dai 20ms, overlap 25%
% moi frame dai 3528 samples, overlap 882 samples
% frame = floor(20*fs/1000);
% ol_percent = 0.25;
% ol_samp = frame * ol_percent;
% shift_samp = frame - ol_samp;
% frame_stop_num = floor(r_len/frame) - 1;
% k = 1;
% window = hamming(frame,'periodic');
% for i = 1 : frame_stop_num
%     windowed_sig = window * r(k:k+frame-1);
%     speech_FFT = fft(windowed_sig,frame);
r_filt_denoise = denoise(r_filtered,fs);


%% ve tin hieu
M = abs(fft(m,m_len));
M_len = length(M);
f = (-m_len/2 : m_len/2 - 1) * (fs / m_len);
S = abs(fft(s,m_len));
r_len = length(r);
R_filtered = abs(fft(r_filt_denoise,r_len));
%sound(r_filt_denoise,fs);

figure('Name', 'Phân tích Phổ Tín hiệu');
subplot(4,1,1); plot(t, m, 'r', 'LineWidth', 1); title('Tín hiệu gốc m(t) và tín hiệu qua điều chế s(t)'); axis([0 12 -1 1]); xlim([1 1.01]); hold on;
                plot(t, s, 'b');
                legend('Tín hiệu gốc m(t)','Tín hiệu qua điều chế s(t)');
subplot(4,1,2); plot(f, fftshift(M)); title('Phổ tín hiệu gốc'); xlim([-10000 10000]);
subplot(4,1,3); plot(f, fftshift(S)); title('Phổ tín hiệu sau điều chế AM (DSB-SC)'); xlim([-100000 100000]);
subplot(4,1,4); plot(f, fftshift(R_filtered)); title('Phổ tín hiệu sau giải điều chế và LPF'); xlim([-10000 10000]);

% so sanh s(t) va r(t)
figure('Name', 'So sánh kênh truyền: Tín hiệu phát s(t) và Tín hiệu thu r(t)');
ax1 = subplot(2, 1, 1);
plot(t, s, 'b');
title('s(t)');
xlabel('Thời gian (s)'); 
ylabel('Biên độ');
grid on;

ax2 = subplot(2, 1, 2);
plot(t, r, 'r');
title(sprintf('r(t)', SNR));
xlabel('Thời gian (s)'); 
ylabel('Biên độ');
grid on;

linkaxes([ax1, ax2], 'x');
xlim(ax1, [0.5 1]); 


% --- 2. So sánh tín hiệu giải điều chế TRƯỚC và SAU khi lọc nhiễu ---
figure('Name', 'Đánh giá hiệu năng thuật toán khử nhiễu (Spectral Subtraction)');

ax3 = subplot(2, 1, 1);
plot(t, r_filtered, 'r'); 
title('Tín hiệu Baseband (r_filtered) trước khi khử nhiễu');
xlabel('Thời gian (s)'); 
ylabel('Biên độ');
grid on;

ax4 = subplot(2, 1, 2);
plot(t, r_filt_denoise, 'b');
title('Tín hiệu Baseband (r_filt_denoise) sau khi khử nhiễu');
xlabel('Thời gian (s)'); 
ylabel('Biên độ');
grid on;

linkaxes([ax3, ax4], 'x');
xlim(ax1, [0.5 1]); 

audiowrite("audio_recieved.wav",r_filt_denoise,fs)