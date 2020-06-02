clc
clear all

load('UBM_SPEAKERS_train.mat');
fs=16000;
for i=3:length(SPEAKERS_train)
    speaker_data=SPEAKERS_train{1,i};
    mfcc_speaker_sentences=[];
    for j=1:7
        raw_speaker_data{1,j}=speaker_data(j).data;
        features1=melcepst(raw_speaker_data{1,j},fs,'EdD');
        Fea = wcmvn((features1)', 151, true);
        %features2=Fea(:,1:179);
        %mfcc_speaker_data{1,j}=Fea;
        mfcc_speaker_sentences=[mfcc_speaker_sentences,Fea];
        clear Fea features1 
    end
   UBM_training_data{1,i-2}=mfcc_speaker_sentences;
end

save('UBM_GMM_data.mat','UBM_training_data');