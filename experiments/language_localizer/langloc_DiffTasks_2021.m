%langloc_DiffTasks
%
%CHANGE LOG
%2016-3-22: created (Matt Siegelman - msieg@mit.edu)
%2019? Matt Siegelman added V5
%2021-06-28: Anna Ivanova (annaiv@mit.edu) 
%            restructured, added the hand icon and response logging to V5
%            V5 and V6 are identical except for verbal instructions
%            (sentiment vs. passive reading)
%2021-08-11: Anna Ivanova
%            add sentiment accuracy info & code for grading
%
%
%PARAMETERS
%Subject = subject name
%run = run number (1-10)
%version = task version (a-f)
%set = set of sentences / nonwords (1-5)
%
%Order 1: Fix S N N S Fix N S N S Fix S N S N Fix N S S N Fix
%Order 2: Fix N S S N Fix S N S N Fix N S N S Fix S N N S Fix
%
%SAMPLE FUNCTION CALL: langloc_DiffTasks('subj12345', 6, 'c', 2)
%
%TASK TIMING (version a): 358 secs
%Fix = fixation cross (14 secs)
%S = sentence block (3 sentences) (18 secs)
%N = nonword block (3 nonword sets) (18 secs)
%
%TASK TIMING (versions b-c): 406 secs
%Fix = fixation cross (14 secs)
%S = sentence block (3 sentences) (21 secs)
%N = nonword block (3 nonword sets) (21 secs)
%
%TASK TIMING (version d): 454 secs
%Fix = fixation cross (14 secs)
%S = sentence block (3 sentences) (24 secs)
%N = nonword block (3 nonword sets) (24 secs)
%
%TASK TIMING (versions e-f): 502 secs
%Fix = fixation cross (14 secs)
%S = sentence block (3 sentences) (27 secs)
%N = nonword block (3 nonword sets) (27 secs)
%
%TRIAL TIMING (version a)
%100ms blank screen
%4800ms sentence / nonwords presentation (12 * 400ms / word)
%400ms hand icon
%700ms blank screen
%total = 6s
%
%TRIAL TIMING (versions b-c)
%100ms blank screen
%4800ms sentence / nonwords presentation (12 * 400ms / word)
%1000ms probe 
%1000ms blank screen
%total = 7s
%
%TRIAL TIMING (version d)
%100ms blank screen
%4800ms sentence / nonwords presentation (12 * 400ms / word)
%2600ms question
%400ms blank screen
%total = 8s
%
%TRIAL TIMING (versions e-f) - NONWORDS CONDITION 
%100ms blank screen
%4800ms nonwords presentation (12 * 400ms / word)
%2600ms MEMORY PROBE
%400ms blank screen
%total = 8s
%
%TRIAL TIMING (versions e-f) - SENTS CONDITION 
%100ms blank screen
%2600ms question
%100ms blank screen
%5200ms sentence presentation (13 * 400ms / word)
%400ms hand icon
%600ms blank screen
%total = 9s
%
%OUTPUT = 'langloc_DiffTasks_subj12345_run1.mat'
%VariableNames = {'Run' 'Version' 'Set' 'Trial' 'Condition' 'Onset' 'Sentence' 'Probe/Question' 'Response' 'RT'}
%
%Change variable 'base_dir' (path to task folder)


function langloc_DiffTasks_2021(subject, run, version, set)

%%%%%%%%%%%%%%%%%%%%
%%% SCRIPT SETUP %%%
%%%%%%%%%%%%%%%%%%%%

%%% RANDOM SEED 
clo = clock;
randseed = ceil(clo(5) + clo(6));
rng('default');
rng(randseed);

%%% TASK VERSION
if strmatch('a',version);
     version = 1;
elseif strmatch('b',version);
    version = 2;
elseif strmatch('c',version);
    version = 3;
elseif strmatch('d',version);
    version = 4;
elseif strmatch('e',version);
    version = 5;
elseif strmatch('f',version);
    version = 6;
else
    "Error - task version should be a letter from 'a' to 'f'";
    keyboard
end;

%%% LOAD STIMULI
if version>4
    load stim_2021;
    stim=stim_2021;
    SENTS = eval(strcat('stim.sents2.set',num2str(set)));  % full sentences
    WORDS = eval(strcat('stim.words2.set',num2str(set)));  % sentences word by word
    NONWORDS = eval(strcat('stim.nonwords.set',num2str(set)));
    QUESTS = eval(strcat('stim.questions2.set',num2str(set)));
    SENTIMENT = eval(strcat('stim.sentiment.set',num2str(set))); 
else
    load stim_v5;
    stim=stim_v5;
    SENTS = eval(strcat('stim.sents.set',num2str(set)));
    WORDS = eval(strcat('stim.words.set',num2str(set)));
    NONWORDS = eval(strcat('stim.nonwords.set',num2str(set)));
    QUESTS = eval(strcat('stim.questions.set',num2str(set)));
end


%%% PICK ANOTHER STIMULUS SET FOR FAKE RESPONSE OPTIONS (FOR MEMORY PROBE)
r_X = randi(5);
while r_X == set;
    r_X = randi(5);
end;    

WORDS_X = eval(strcat('stim.words.set',num2str(r_X)));
NONWORDS_X = eval(strcat('stim.nonwords.set',num2str(r_X)));


%%% SET UP A STRUCT TO KEEP TRACK OF HOW MANY RUNS WERE RUN FOR EACH
%%% VERSION
if run == 1;
    r = randperm(48);
    v.r = r; 
    v.v1i = 0;
    v.v2i = 0;
    v.v3i = 0;
    v.v4i = 0;
    v.v5i = 0;
    v.v6i = 0;
    v1i = v.v1i;
    v2i = v.v2i;
    v3i = v.v3i;
    v4i = v.v4i;
    v5i = v.v5i;
    v6i = v.v6i;
    save('v.mat','v');
else;
    load v.mat
    r = v.r;
    v1i = v.v1i
    v2i = v.v2i
    v3i = v.v3i;
    v4i = v.v4i;
    v5i = v.v5i;
    v6i = v.v6i;
end;

%%% SENTENCE PERMUTATION & UPDATING THE RUN COUNT
if version == 1;
    v1i = v1i + 1;
    v.v1i = v1i;
    rTrials = r(1+24*(v1i-1):24+24*(v1i-1));
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:12);
    nonwords = NONWORDS(rTrials,1:12);
    
    if v1i ==1;
        ord = stim.ord1;
    elseif v1i ==2;
        ord = stim.ord2
    end;
    
    trial_dur = 6;
    
elseif version == 2;
    v2i = v2i + 1;
    rTrials = r(1+24*(v2i-1):24+24*(v2i-1));
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:12);
    nonwords = NONWORDS(rTrials,1:12);
    
    if v2i ==1;
        ord = stim.ord1;
    elseif v2i ==2;
        ord = stim.ord2;
    end;
    
    trial_dur = 7;
    
elseif version == 3;
    v3i = v3i + 1;
    rTrials = r(1+24*(v3i-1):24+24*(v3i-1));
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:12);
    nonwords = NONWORDS(rTrials,1:12);
    
    if v3i ==1;
        ord = stim.ord1;
    elseif v3i ==2;
        ord = stim.ord2;
    end;
    
    trial_dur = 7;

elseif version == 4;
    v4i = v4i+1;
    
    if v4i ==1;
        ord = stim.ord1;
        r5 = randperm(24);
        v.v4i = v4i
        v.r5 = r5;
    elseif v4i ==2;
        ord = stim.ord2
        r5 = v.r5;
    end;

    rTrials = r5(1+12*(v4i-1):12+12*(v4i-1));
    rTrials(13:24) = rTrials + 24;
    rTrials = rTrials(randperm(24));
    
    quests = QUESTS(rTrials,:);
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:12);
    nonwords = NONWORDS(rTrials,1:12);
    
    trial_dur = 8;

elseif version == 5;
    v5i = v5i+1;
    
    if v5i ==1;
        ord = stim.ord1;
        r5 = randperm(24);
        v.v5i = v5i
        v.r5 = r5;
    elseif v5i ==2;
        ord = stim.ord2;
        r5 = v.r5;
    end;
    
    rTrials = r(1+24*(v5i-1):24+24*(v5i-1));

    quests = QUESTS(rTrials,:);
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:13);
    nonwords = NONWORDS(rTrials,1:12);
    sentiment = SENTIMENT(rTrials,:);
    
    trial_dur = 9;
    
elseif version == 6;
    v6i = v6i+1;
    
    if v6i ==1;
        ord = stim.ord1;
        r6 = randperm(24);
        v.v6i = v6i
        v.r6 = r6;
    elseif v6i ==2;
        ord = stim.ord2;
        r6 = v.r6;
    end;
    
    rTrials = r(1+24*(v6i-1):24+24*(v6i-1));

    quests = QUESTS(rTrials,:);
    sents = SENTS(rTrials,1);
    words = WORDS(rTrials,1:13);
    nonwords = NONWORDS(rTrials,1:12);
    
    trial_dur = 9;
end;

r_NW1 = mod(randperm(24),2)+1;
r_NW2 = mod(randperm(24),2)+1;

%%% CONDITION INDICES
Fi = 0;       % fixation      
Si = 0;       % sent
Ni = 0;       % nonwords
Ci = 0;
Ti = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PSYCHTOOLBOX SETUP %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

Screen('Preference', 'SkipSyncTests', 1)
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

[window, winRect] = PsychImaging('OpenWindow', screenNumber, white);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the on screen window in pixels
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
[xCenter, yCenter] = RectCenter(winRect);

Screen('TextSize', window, 80);
Screen('TextFont', window, 'Courier');
Screen('TextStyle', window, 0);

%Hand Icon
myimgfile = 'hand-press-button-4.eps';
img=imread(myimgfile);
textureIndex = Screen('MakeTexture',window,img);

%Keyboard
[keyNames, Button, kbIdx, oldKeyboardPrefs] = setUpPTBkeyboard();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% START THE EXPERIMENT %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wait for trigger
waitingText = 'Waiting for scanner...';
DrawFormattedText(window, waitingText, 'center', 'center');
Screen('Flip', window);
        
%Flip screen when scanner triggers
runOnset = waitForTrigger(kbIdx, Button.trigger, Button.escape, window);

% Set up stimuli onsets 
% (Anya: idk why the numbers are arranged the way they are)
on = GetSecs;
if version == 1 ;
    fix_onsets = on + stim.fix_onsets;
    blank_onsets = on + stim.blank_onsets;
    onsets = on + stim.onsets;
    resp_onsets = on + stim.resp_onsets;
elseif version == 2 | version == 3 ;
    fix_onsets = on + stim.fix_onsets4;
    blank_onsets = on + stim.blank_onsets4;
    onsets = on + stim.onsets4;
    resp_onsets = on + stim.resp_onsets4;
elseif version == 4;
    fix_onsets = on + stim.fix_onsets5;
    blank_onsets = on + stim.blank_onsets5;
    onsets = on + stim.onsets5;
    resp_onsets = on + stim.resp_onsets5;
elseif version == 5 | version == 6;
    fix_onsets = on + stim.fix_onsets6;
    blank_onsets = on + stim.blank_onsets6;
    onsets = on + stim.onsets6;
    resp_onsets = on + stim.resp_onsets6;
end;


%%% PRESENT THE STIMULI
for z = 1:length(ord);
    
    % Fixation
    if strmatch('F',ord(z)) == 1;
        
        Fi = Fi+1;
        
        DrawFormattedText(window, '+', 'center', 'center', black);  
        Screen('Flip', window, fix_onsets(Fi));
        
        WaitSecs(14);        
        continue;
    
    % Otherwise, set up the materials
    else      
        if strmatch('S',ord(z)) == 1;
            stim1 = words;
        elseif strmatch('N',ord(z)) == 1;
            stim1 = nonwords;
        end;  
    end;

    Oi = 0;
    
    % In each trial
    for i = Ti:Ti+2;

        % Count the # of trials presented
        if strmatch('S',ord(z)) == 1;
                Si = Si+1;
                Ci = Si;
                do_S=1;
                do_N=0;
        elseif strmatch('N',ord(z)) == 1;
                Ni = Ni+1;   
                Ci = Ni;
                do_S=0;
                do_N=1;
        end;

        Oi = Oi+1;

        DrawFormattedText(window, ' ', 'center', 'center', black);  
        Screen('Flip', window, blank_onsets(ceil(Ti/3))+trial_dur*(Oi-1));

        % If V1-V4 OR nonword trial, show 12 words/nonwords as usual
        % otherwise show 13 & question beforehand
        if version<5 | do_N==1;
            numWords = 12;
            offset = 0;
        else
            numWords = 13;

            pres1 = char(quests(Ci,1));
            pres_time = 2.6;
            offset = pres_time;

            DrawFormattedText(window, pres1, 'center', 'center', black, 18); 
            Screen('Flip', window, onsets(ceil(Ti/3))+trial_dur*(Oi-1))

            DrawFormattedText(window, ' ', 'center', 'center', black);  
            Screen('Flip', window, onsets(ceil(Ti/3))+trial_dur*(Oi-1)+pres_time);
        end
            

        for j = 1:numWords;

            w = char(stim1(Ci,j));

            DrawFormattedText(window, upper(w), 'center', 'center', black);  
            [~, actualFlipTime, ~, ~, ~] = Screen('Flip', window, onsets(ceil(Ti/3))+trial_dur*(Oi-1)+0.4*(j-1)+offset);    

            % Set up the response matrix at the first word/nonword
            if j == 1;
            behmat(Ti,1) = {run};
            behmat(Ti,2) = {version};
            behmat(Ti,3) = {set};
            behmat(Ti,4) = {Ti};
            behmat(Ti,5) = {ord(z)};
            behmat(Ti,6) = {actualFlipTime - on};

            if strmatch('S',ord(z)) == 1;
                behmat(Ti,7) = sents(Ci,1);
            elseif strmatch('N',ord(z)) == 1;
                behmat(Ti,7) = {'Nonword_sequence'};
            end;

            end;

        end;

        % show the last word
        WaitSecs(0.398);

        % white screen after the sentence/NW string
        DrawFormattedText(window, ' ', 'center', 'center', black);  
        Screen('Flip', window)
        WaitSecs(0.098);


        %%% SET UP THE RESPONSE SCREEN
        if version == 1;
            pres = 'Hand';
            behmat(Ti,8) = {'NaN'};
        elseif version == 2;
            r_probe = randi([2 12]);
            
            % Determine which probe word to show - right or wrong
            if strmatch('S',ord(z));

            if r_NW1(Ci) == 1;
                behmat(Ti,8) = {1};
                pres = char(stim1(Ci,r_probe));
                g = find(pres=='.');
                pres(g) = '';
            elseif r_NW1(Ci) == 2;
                behmat(Ti,8) = {2};
                pres = char(WORDS_X(randi(48),r_probe));
                g = find(pres=='.');
                pres(g) = '';
                while strmatch(pres,stim1(Ci,:));
                    pres = char(WORDS_X(randi(48),r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                end;  
            end;

            elseif strmatch('N',ord(z));
            if r_NW2(Ci) == 1;
                behmat(Ti,8) = {1};
                pres = char(stim1(Ci,r_probe));
                g = find(pres=='.');
                pres(g) = '';
            elseif r_NW2(Ci) == 2;
                behmat(Ti,8) = {2};
                pres = char(NONWORDS_X(randi(48),r_probe));
                g = find(pres=='.');
                pres(g) = '';
                while strmatch(pres,stim1(Ci,:));
                    pres = char(NONWORDS_X(randi(48),r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                end;
            end; 
            end;

        elseif version == 3
            % Determine which probe word to show - right or wrong 
            % (1st only)
            if strmatch('S',ord(z));

            if r_NW1(Ci) == 1;
                behmat(Ti,8) = {1};
                pres = char(stim1(Ci,12));
                g = find(pres=='.');
                pres(g) = '';
            elseif r_NW1(Ci) == 2;
                behmat(Ti,8) = {2};
                pres = char(WORDS_X(randi(48),12));
                g = find(pres=='.');
                pres(g) = '';
                while strmatch(pres,stim1(Ci,:));
                    pres = char(WORDS_X(randi(48),12));
                    g = find(pres=='.');
                    pres(g) = '';
                end;
            end;
            elseif strmatch('N',ord(z));
            if r_NW2(Ci) == 1;
                behmat(Ti,8) = {1};
                pres = char(stim1(Ci,12));
                g = find(pres=='.');
                pres(g) = '';
            elseif r_NW2(Ci) == 2;
                behmat(Ti,8) = {2};
                pres = char(NONWORDS_X(randi(48),12));
                g = find(pres=='.');
                pres(g) = '';
                while strmatch(pres,stim1(Ci,:));
                    pres = char(NONWORDS_X(randi(48),12));
                    g = find(pres=='.');
                    pres(g) = '';
                end;
            end;

            end;
        elseif version == 4;
            r_probe = randi([2 12]);
            if strmatch('S',ord(z));
                if strmatch('Yes',quests(Ci,2));
                    behmat(Ti,8) = {1};
                elseif strmatch('No',quests(Ci,2));
                    behmat(Ti,8) = {2};
                end;

                pres1 = char(quests(Ci,1));

            elseif strmatch('N',ord(z)); 

                if r_NW2(Ci) == 1;
                    behmat(Ti,8) = {1};
                    pres = char(stim1(Ci,r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                elseif r_NW2(Ci) == 2;
                    behmat(Ti,8) = {2};
                    pres = char(NONWORDS_X(randi(48),r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                    while strmatch(pres,stim1(Ci,:));
                        pres = char(NONWORDS_X(randi(48),r_probe));
                        g = find(pres=='.');
                        pres(g) = '';
                    end;
                end;
            end;
      

        elseif version == 5;
            r_probe = randi([2 12]);
            if strmatch('S',ord(z));
                % Show hand icon. Correct answer = sentiment
                pres1 = 'Hand';
                sentiment{Ci}
                if 1==sentiment{Ci};
                    behmat(Ti,8) = {1};
                elseif 2==sentiment{Ci};
                    behmat(Ti,8) = {2};
                else;
                    behmat(Ti,8) = {'NA'};
                end;


            elseif strmatch('N',ord(z)); 

                if r_NW2(Ci) == 1;
                    behmat(Ti,8) = {1};
                    pres = char(stim1(Ci,r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                elseif r_NW2(Ci) == 2;
                    behmat(Ti,8) = {2};
                    pres = char(NONWORDS_X(randi(48),r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                    while strmatch(pres,stim1(Ci,:));
                        pres = char(NONWORDS_X(randi(48),r_probe));
                        g = find(pres=='.');
                        pres(g) = '';
                    end;
                end;
            end;
            
       elseif version == 6;
            r_probe = randi([2 12]);
            if strmatch('S',ord(z));
                % Show hand icon. No correct answer
                  pres1 = 'Hand';
                  behmat(Ti,8) = {'NA'};

            elseif strmatch('N',ord(z)); 

                if r_NW2(Ci) == 1;
                    behmat(Ti,8) = {1};
                    pres = char(stim1(Ci,r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                elseif r_NW2(Ci) == 2;
                    behmat(Ti,8) = {2};
                    pres = char(NONWORDS_X(randi(48),r_probe));
                    g = find(pres=='.');
                    pres(g) = '';
                    while strmatch(pres,stim1(Ci,:));
                        pres = char(NONWORDS_X(randi(48),r_probe));
                        g = find(pres=='.');
                        pres(g) = '';
                    end;
                end;
            end;
        end;

        %%% DRAW PROMPT SCREEN

            if version == 1;
                Screen('DrawTexture', window, textureIndex);    
                pres_time = 0.4;
                resp_time = 1.1;
            elseif version == 2 | version == 3;
                DrawFormattedText(window, upper(pres), 'center', 'center', [9 0 0]); 
                pres_time = 1;
                resp_time = 2;
            elseif version == 4;
                if strmatch('S',ord(z));
                    DrawFormattedText(window, pres1, 'center', 'center', black, 18); 
                elseif strmatch('N',ord(z));
                    DrawFormattedText(window, upper(pres), 'center', 'center', [9 0 0]);
                end;
                pres_time = 2.6;
                resp_time = 3;
            elseif version == 5 | version == 6;
                if strmatch('S',ord(z));
                    Screen('DrawTexture', window, textureIndex); 
                    pres_time = 0.4;
                    resp_time = 1.0;
                elseif strmatch('N',ord(z));
                    DrawFormattedText(window, upper(pres), 'center', 'center', [9 0 0]);
                    pres_time = 2.6;
                    resp_time = 3;
                end;
            end; 

            Screen('Flip', window, resp_onsets(ceil(Ti/3))+trial_dur*(Oi-1)+0.1+offset);
            

            %%% RECORD RESPONSE
            
            % Set up
            pressed = 0;
            response = 'NA'; %will equal 1 if the subj presses 1 while the probe is on
            rt = 'NA'; %will equal (time of button press) - (time of probe onset)
            behmat(Ti,9) = {response};
            behmat(Ti,10) = {rt};
            get = GetSecs;
            
            % Wait for a key press
            while GetSecs < get + resp_time;
                [keyIsDown, responseTime, keyCode] = KbCheck(kbIdx);
                if GetSecs > get + pres_time;
                    DrawFormattedText(window, ' ', 'center', 'center', black);  
                    Screen('Flip', window, resp_onsets(ceil(Ti/3))+trial_dur*(Oi-1)+pres_time);
                end;
                     if keyIsDown == 1;
                            if ismember(find(keyCode == 1), Button.one);
                                rt = responseTime - get;
                                response = 1;
                                behmat(Ti,9) = {response};
                                behmat(Ti,10) = {rt};
                                pressed = 1;
                                DrawFormattedText(window, ' ', 'center', 'center', black);  
                                Screen('Flip', window, resp_onsets(ceil(Ti/3))+trial_dur*(Oi-1)+pres_time);
                            elseif ismember(find(keyCode == 1), Button.two);
                                rt = responseTime - get;
                                response = 2;
                                behmat(Ti,9) = {response};
                                behmat(Ti,10) = {rt};
                                pressed = 1;
                                DrawFormattedText(window, ' ', 'center', 'center', black);  
                                Screen('Flip', window, resp_onsets(ceil(Ti/3))+trial_dur*(Oi-1)+pres_time);
                            end;
                     end;
            end        
    
    Ti = Ti + 1; 
    Ci = Ci + 1;
    
    end;
    

end;
   
%%% SAVE OUTPUT FILE
behmat1 = cell2table(behmat,'VariableNames',{'Run' 'Version' 'Set' 'Trial' 'Condition' 'Onset' 'Sentence' 'Probe_or_Question' 'Response' 'RT'});
fname = fullfile('Output',...
    char(strcat('langloc_DiffTasks_',subject,'_run',num2str(run),'.mat')));
if exist(fname,'file') == 2;
    fname = fullfile('Output',...
        char(strcat('langloc_DiffTasks_',subject,'_run',num2str(run),'-2.mat')));
end;
save(fname,'behmat1');   
 


%%% UPDATE RUN COUNT
v.r = r;
if version == 4;
v.r5 = r5;
end;

v.v1i = v1i;
v.v2i = v2i;
v.v3i = v3i;
v.v4i = v4i;
v.v5i = v5i;

save('v.mat','v');


%%% DONE
sca;
RestrictKeysForKbCheck(oldKeyboardPrefs.enableKeys);

end 

        














    