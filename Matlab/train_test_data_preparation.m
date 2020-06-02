clc
clear all

%files = dir;   % assume starting from current directory
files = dir('C:\Users\PC\Desktop\i_vecotrs_pokus_FINAL\DR1_DR2_DR3_DR4\');
filenames = {files.name};
subdirs = filenames([files.isdir]);
for s = 3:length(subdirs)
  subdir = subdirs{s};
  % process subdirectory
  disp(subdir);   % for example
    directory=['C:\Users\PC\Desktop\i_vecotrs_pokus_FINAL\DR1_DR2_DR3_DR4\',subdir];
    speaker_data = dir(directory);
   % fullfile(['D:\matlab_mat\timit\DR1\',subdir],'SA1.wav')
    num=1;
    for i=1:length(speaker_data)
        str=speaker_data(i).name;
        k = strfind(str,'WAV');
        if k ~= 0
            sentences(num).name=speaker_data(i).name;
            num=num+1;
        end
    end
    clear str k i
    
    [data1, fs] = audioread(fullfile(directory,'SA1.wav'));
    speaker(1).name=subdir;
    speaker(1).wav_sentence='SA1.wav';
    speaker(1).data=data1;
    speaker(1).fs=fs;
    
    clear data1 fs
    
    [data1, fs] = audioread(fullfile(directory,'SA2.wav'));
    speaker(2).name=subdir;
    speaker(2).wav_sentence='SA1.wav';
    speaker(2).data=data1;
    speaker(2).fs=fs;
    clear data1 fs
    
    m=3;
    for j=1:length(sentences)
        str=sentences(j).name;
        k = strfind(str,'SX');
        if k ~= 0
           speaker(m).name=subdir;
           speaker(m).wav_sentence=sentences(j).name;
           [data1, fs] = audioread(fullfile(directory,sentences(j).name));
           speaker(m).data=data1;
           speaker(m).fs=fs;
           m=m+1;
        end
        clear data1 fs
    end
    SPEAKERS_train{s}=speaker;
    clear num str k m speaker j
    
    m=1;
    for n=1:length(sentences)
        str=sentences(n).name;
        k = strfind(str,'SI');
        if k ~= 0
           speaker(m).name=subdir;
           speaker(m).wav_sentence=sentences(n).name;
           [data1, fs] = audioread(fullfile(directory,sentences(n).name));
           speaker(m).data=data1;
           speaker(m).fs=fs;
           m=m+1;
        end
        clear data1 fs
    end
    SPEAKERS_test{s}=speaker;
    clear str k m n
    clear subdir speaker 
    
    
end