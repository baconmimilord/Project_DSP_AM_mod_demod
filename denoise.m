function denoised_sig = denoise(sig, fs)
    sig = sig(:); % chuyen tin hieu thanh vector cot
    sig_len = length(sig);
    
    % Su dung cua so 20ms cho giong noi
    frame_dur = 20 / 1000; 
    frame_len = floor(frame_dur * fs); % = 3528 samples, fs = 176400
    
    % Su dung overlap 50%
    ol_samp = floor(frame_len * 0.5);
    shift_samp = frame_len - ol_samp;
    
    % Su dung cua so Hanning
    window = hann(frame_len, 'periodic'); 
    
    % Tinh so khung can co
    num_frames = floor((sig_len - frame_len) / shift_samp) + 1;
    
    % Khoi tao ma tran khung
    frames = zeros(num_frames, frame_len);
    
    % Tao khung la ma tran voi cac vector hang la 1 khung thu duoc tu viec
    % nhan tin hieu voi cua so dich
    idx = 1;
    for i = 1 : num_frames
        frames(i, :) = sig(idx : idx + frame_len - 1) .* window;
        idx = idx + shift_samp;
    end
    
    % Uoc luong nhieu tu 10 khung dau tien
    noise_est = zeros(1, frame_len);
    num_noise_frames = 10;
    for i = 1 : num_noise_frames
        noise_spec = fft(frames(i, :));
        noise_est = noise_est + abs(noise_spec);
    end
    noise_est = noise_est / num_noise_frames;
    
    % Khoi tao vector tin hieu sau tru pho
    denoised_sig = zeros(sig_len, 1);
    idx = 1;
    
    for i = 1 : num_frames
        % Tinh fft
        complex_spec = fft(frames(i, :));
        mag_spec = abs(complex_spec);
        phase_spec = angle(complex_spec);
        
        % Tru pho, he so alpha = 1.5
        clean_spec = mag_spec - 1.5 * noise_est;
        clean_spec(clean_spec < 0) = 0;
        
        % Khoi phuc pho phuc
        fft_clean_spec = clean_spec .* exp(1i * phase_spec);
        
        % Dua ve mien thoi gian
        denoise_frame = real(ifft(fft_clean_spec));
        
        % Cong cac khung
        denoised_sig(idx : idx + frame_len - 1) = denoised_sig(idx : idx + frame_len - 1) + denoise_frame(:);
        idx = idx + shift_samp; 
    end
end