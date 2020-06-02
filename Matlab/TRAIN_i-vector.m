clc
clear all
tic

%% Load UBM_GMM
load('UBM_GMM_data_ALL.mat')
zmena=UBM_training_data(1,1:50);

delete(gcp('nocreate'))
nworkers = 2;
nworkers = min(nworkers, feature('NumCores'));
 isopen = parpool('local')>0;
%if ~isopen, parpool(nworkers); end

%gmm = gmm_em(mfcc_speaker_data', Number_of_Gaussian, 15, 1,nworkers);
gmm_ubm_model = gmm_em(zmena', 256, 25,1,nworkers,'gmm_ubm_model');

%% Training observations
load('SPEAKERS_TRAIN.mat')
fs=16000;
nChannels=7;
n=160;
%trainSpeakerData = cell(nSpeakers, nChannels);
for i=3:length(SPEAKERS_train)
    speaker_data=SPEAKERS_train{1,i};
    mfcc_speaker_sentences=[];
    for j=1:7
        raw_speaker_data{1,j}=speaker_data(j).data;
        features1=melcepst(raw_speaker_data{1,j},fs,'EdD',12,n);
        Fea = wcmvn((features1)', 151, true);
        %mfcc_speaker_data{1,j}=Fea;
        clear features1 
        %Features={};
        %Features{1}=Fea;
        %mfcc_speaker_sentences=[mfcc_speaker_sentences,Fea];
        trainSpeakerData{i-2, j}=Fea;
        speakerID(i-2, j) = i-2;
        clear Fea features1 
        %Training_speaker_data{i-2,j}=Fea;
    end
    %Speakers_training_data{1,i-2}=mfcc_speaker_sentences;
    
end
clear i j

%%Calculate the statistics needed for the iVector model.
ubm=gmm_ubm_model;

nSpeakers=106;
nChannels=7;
stats = cell(nSpeakers, nChannels);
for s=1:nSpeakers
    for c=1:nChannels
        [N,F] = compute_bw_stats(trainSpeakerData{s,c}, ubm);
        stats{s,c} = [N; F];
    end
end
%%
%Learn the total variability subspace from all the speaker data.
tvDim = 100;
niter = 5;
T = train_tv_space(stats(:), ubm, tvDim, niter, nworkers);
% Now compute the ivectors for each speaker and channel.  


devIVs = zeros(tvDim, nSpeakers, nChannels);
for s=1:nSpeakers
  for c=1:nChannels
      devIVs(:, s, c) = extract_ivector(stats{s, c}, ubm, T);
  end
end

%%LDA on the iVectors to find the dimensions that matter.

   ldaDim = min(100, nSpeakers-1);
   devIVbySpeaker = reshape(devIVs, tvDim, nSpeakers*nChannels);
   [V,D] = lda(devIVbySpeaker, speakerID(:));
   finalDevIVs = V(:, 1:ldaDim)' * devIVbySpeaker;
   
 %%Train a Gaussian PLDA model with development i-vectors
 
 
 nphi = ldaDim;                  
 niter = 10;
 pLDA = gplda_em(finalDevIVs, speakerID(:), nphi, niter);
   
 %% We have the channel and LDA models. Let's build 

 averageIVs = mean(devIVs, 3);   % Average IVs across channels.
 modelIVs = V(:, 1:ldaDim)' * averageIVs;
 
 %% Test speakers
load('SPEAKERS_TEST.mat')
fs=16000;
for i=3:length(SPEAKERS_test)
    speaker_data=SPEAKERS_test{1,i};
    mfcc_speaker_sentences=[];
    for j=1:3
        raw_speaker_data{1,j}=speaker_data(j).data;
        features1=melcepst(raw_speaker_data{1,j},fs,'EdD',12,n);
        Fea = wcmvn((features1)', 151, true);
        %mfcc_speaker_data{1,j}=Fea;
        clear features1 
        %Features={};
        %Features{1}=Fea;
        %mfcc_speaker_sentences=[mfcc_speaker_sentences,Fea];
        testSpeakerData{i-2, j}=Fea;
        %speakerID(i-2, j) = i-2;
        clear Fea features1 
    end 
end
clear i j
 %%
 %Compute the ivectors for the test set 
 nChannels=3;
 testIVs = zeros(tvDim, nSpeakers, nChannels);
 for s=1:nSpeakers
     for c=1:nChannels
         [N, F] = compute_bw_stats(testSpeakerData{s, c}, ubm);
         testIVs(:, s, c) = extract_ivector([N; F], ubm, T);
     end
 end
 
 testIVbySpeaker = reshape(permute(testIVs, [1 3 2]), ...
                            tvDim, nSpeakers*nChannels);
 finalTestIVs = V(:, 1:ldaDim)' * testIVbySpeaker;
 
 %%
 %Score the models with all the test data.
 ivScores = score_gplda_trials(pLDA, modelIVs, finalTestIVs);
 imagesc(ivScores)
 title('Speaker Verification Likelihood (iVector Model)');
 xlabel('Test # (Channel x Speaker)'); ylabel('Model #');
 colorbar; axis xy; drawnow;
 answers = zeros(nSpeakers*nChannels*nSpeakers, 1);
 for ix = 1 : nSpeakers,
     b = (ix-1)*nSpeakers*nChannels + 1;
     answers((ix-1)*nChannels+b : (ix-1)*nChannels+b+nChannels-1)= 1;
 end
 
 ivScores = reshape(ivScores', nSpeakers*nChannels* nSpeakers, 1);
 
 figure;
 eer = compute_eer(ivScores, answers, true);
 
 %% Metric
 posledne = score_gplda_trials(pLDA, modelIVs, finalTestIVs);
 poc=0;
 poc1=0;
 speaker=1;
for ith_trial=1:318
   
     [M,I]=max(posledne(:,ith_trial));
        
        if I == speaker
           poc=poc+1;
        else
           poc1=poc1+1;
        end
        if (poc + poc1) == 3
            acc(speaker)=(poc/3)*100;
            speaker=speaker+1;
            poc=0;
            poc1=0;
        end
 end
 
mean(acc)
toc