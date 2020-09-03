% ind = '/home/bcowley/Benslab/CENT/project_TOVA/TOVA-data/paper1';
ind = '/wrk/group/hipercog/project_TOVA/ANALYSIS/paper1';
% oud = '/home/bcowley/Benslab/CENT/project_TOVA/ANALYSIS/paper1_extended_anal';
oud = '/wrk/group/hipercog/project_TOVA/ANALYSIS/paper1/PLV';

ROI = {[7 19 36 21 15 23 28] [68 85 100]
        'parieto-occipital' 'frontal'};
grp = {'Control' 'ADHD'};
cnd = {'' 'rt'
    'Target-locked' 'Response-locked'};

lbwh = get(0,'ScreenSize');
clrmp = {'greytight'
'whatjet(''what'', [0.9 0.9 0.9], ''stops'', [0 0.15 0.25 0.1 0.1 0.25 0.15])'};
cmap = eval(clrmp{2, 1});


% LOAD CORRECT RESPONSE DATA
cEEG = pop_loadset('filepath', ind...
                 , 'filename', 'CONTROL_MERGED_randomised_COR_RSP_TOTAL.set');
aEEG = pop_loadset('filepath', ind...
                 , 'filename', 'ADHD_MERGED_randomised_COR_RSP_TOTAL.set');

% epoch aligned to RT
ix = [cEEG.event(ismember({cEEG.event.type}, 'cor_rsp')).duration] > 600;
cEEGrt = pop_epoch(pop_select(cEEG, 'notrial', ix), {'RESP'}, [-0.6 0.4]);
ix = [aEEG.event(ismember({aEEG.event.type}, 'cor_rsp')).duration] > 600;
aEEGrt = pop_epoch(pop_select(aEEG, 'notrial', ix), {'RESP'}, [-0.6 0.4]);

% Subset by median RT
Crts = eeg_getepochevent(cEEG, {'cor_rsp'}, [], 'duration');
idx = Crts < median(Crts);
cEEGloRT = pop_select(cEEG, 'trial', find(idx));
cEEGhiRT = pop_select(cEEG, 'trial', find(~idx));
Arts = eeg_getepochevent(aEEG, {'cor_rsp'}, [], 'duration');
idx = Arts < median(Arts);
aEEGloRT = pop_select(aEEG, 'trial', find(idx));
aEEGhiRT = pop_select(aEEG, 'trial', find(~idx));


% Phase-locking tests
roi = sort([ROI{1, :}]);
tx = biosemi1020(roi);
filtSpec.range = [6 10];
filtSpec.order = 300;
nbootci = 100;

% calculate PLV & bootstrap 95% CIs of sliding windows...
wdwinc = 100;
wdwstarts = -200:wdwinc:600;
sldngwdws = cell(numel(wdwstarts));

for sw = 1:numel(sldngwdws)
    tms = [wdwstarts(sw) wdwstarts(sw) + wdwinc * 2];
    % calculate PLV & bootstrap 95% CIs of whole epoch...
    [Cplv, CplvCI, Ctime] = sbf_get_plv(cEEG, roi, tms, filtSpec, nbootci);
    [Aplv, AplvCI, Atime] = sbf_get_plv(aEEG, roi, tms, filtSpec, nbootci);

    % ...and for +/- median RT
    [CloRTplv, CloRTplvCI, CloTime] = ...
                        sbf_get_plv(cEEGloRT, roi, tms, filtSpec, nbootci);
    [ChiRTplv, ChiRTplvCI, ChiTime] = ...
                        sbf_get_plv(cEEGhiRT, roi, tms, filtSpec, nbootci);
    [AloRTplv, AloRTplvCI, AloTime] = ...
                        sbf_get_plv(aEEGloRT, roi, tms, filtSpec, nbootci);
    [AhiRTplv, AhiRTplvCI, AhiTime] = ...
                        sbf_get_plv(aEEGhiRT, roi, tms, filtSpec, nbootci);
    sldngwdws{sw} = {Cplv, CplvCI, Ctime
                     Aplv, AplvCI, Atime
                     CloRTplv, CloRTplvCI, CloTime
                     ChiRTplv, ChiRTplvCI, ChiTime
                	 AloRTplv, AloRTplvCI, AloTime
                     AhiRTplv, AhiRTplvCI, AhiTime};
end

tms = [-200 800];

% calculate PLV & bootstrap 95% CIs of whole epoch...
[Cplv, CplvCI, Ctime] = sbf_get_plv(cEEG, roi, tms, filtSpec, nbootci);
[Aplv, AplvCI, Atime] = sbf_get_plv(aEEG, roi, tms, filtSpec, nbootci);

% ...and for +/- median RT
[CloRTplv, CloRTplvCI, CloTime] = ...
                    sbf_get_plv(cEEGloRT, roi, tms, filtSpec, nbootci);
[ChiRTplv, ChiRTplvCI, ChiTime] = ...
                    sbf_get_plv(cEEGhiRT, roi, tms, filtSpec, nbootci);
[AloRTplv, AloRTplvCI, AloTime] = ...
                    sbf_get_plv(aEEGloRT, roi, tms, filtSpec, nbootci);
[AhiRTplv, AhiRTplvCI, AhiTime] = ...
                    sbf_get_plv(aEEGhiRT, roi, tms, filtSpec, nbootci);


sldngwdws{end + 1} = {Cplv, CplvCI, Ctime
                     Aplv, AplvCI, Atime
                     CloRTplv, CloRTplvCI, CloTime
                     ChiRTplv, ChiRTplvCI, ChiTime
                	 AloRTplv, AloRTplvCI, AloTime
                     AhiRTplv, AhiRTplvCI, AhiTime};

save(fullfile(oud, ['PLV' num2str(now) '.mat']), 'sldngwdws', '-v7.3')


function [plv, plvCI, plvTime] = sbf_get_plv(eeg, roi, millis, filtSpec, nbootci)

    t1 = max(millis(1) - filtSpec.order, eeg.xmin * 1000);
    t2 = min(millis(2) + filtSpec.order, eeg.xmax * 1000);
    calcseg = find(eeg.times >= t1, 1) : find(eeg.times <= t2, 1, 'last');
    plvTime = eeg.times(calcseg);

    bootrep = {'' sprintf(' (with 95%% CIs from %d bootstraps)', nbootci)};
    fprintf('%s%s for %s;\nCalc segment:%d..%dms to extract:%d..%dms\n'...
        , 'Calculating Phase-locking value', bootrep{(nbootci > 0) + 1}...
        , eeg.setname, t1, t2, millis(1), millis(2))

    % calculate PLV
    [calcCplv, CI] = eegPLV(eeg.data(roi, calcseg, :), eeg.srate, filtSpec...
                            , 'nbootci', nbootci);
    
    use1 = find(eeg.times >= millis(1), 1) - calcseg(1) + 1;
    use2 = ceil((((millis(2) - millis(1)) / 1000) * eeg.srate) + use1);
    plv = calcCplv(use1:use2, :, :);
    if ~isempty(CI)
        plvCI = CI(use1:use2, :, :, :);
    end
    plvTime = plvTime(use1:use2);
end
