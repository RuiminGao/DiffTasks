function grid_MDloc_ips224_2021( sessionID , order )
% Spatial( sessionID , order )

% order determines order of blocks: (THIS IS NOT CORRECT!) -Jin
% run = 1 : HEEH - EHEH - HEHE - EHHE
% run = 2 : EHHE - HEHE - EHEH - HEEH

% how to run:
% 1st run: grid_MDloc_ips224_2021('FED_20210927a_3T1', 1)
% 2nd run: grid_MDloc_ips224_2021('FED_20210927a_3T1', 2)

% original author unknown
% revised by Jason Webster, Kanwisher Lab, 2009 March 13
% revised again by Ben Lipkin, Fedorenko Lab, 2021 Aug 26

Screen('Preference', 'SkipSyncTests', 1); % debugging

rootDir=pwd;
dataDir=fullfile(rootDir,'data');
if ~exist(dataDir,'dir')
    mkdir(dataDir)
end

if ~(ischar(sessionID))
    error('SessionID must be a string')
end
filename = [sessionID,'_',num2str(order),'_data.txt'];
if exist(fullfile(dataDir,filename),'file')
    error(['This subject already completed order ',num2str(order),'. Try order ',num2str(order+1)]);
end

%set fixation and presentation times for trials
fixtime = 0.500;
prestime = 1.000;
feedbacktime = 0.250;

trials = 4;   %number of trials per block
trialLength = 8;
fixBlockLength = 16;
trialBlockLength = 32;

KbName('UnifyKeyNames');
onExit='execution halted by experimenter';

nextTime = 0;
blockEnd = 0;
rownum = 0;

%create cell matrix that will save the data from this run of trials
cd(dataDir);  dataFile=fopen(filename,'wt');
subjData = cell(50,8);  %two lines of header info and 48 trials
subjData{1,1} = datestr(clock);  %store timestamp of start of program and write the header
subjData(2,1:8) = {'Subject', 'Trial','Condition','Item','Accuracy','Response time','Contents','Fake ans'};
fprintf(dataFile,'%s\n',subjData{1,1});
fprintf(dataFile,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',subjData{2,1:8});

%this defines the order of difficulty conditions for the different blocks
order = mod((order+1),2)+1; % cycle orders via modulo
if     order==1, condition = {'+','easy','hard','hard','easy','+','hard','easy','easy','hard','+','easy','hard','hard','easy','+'};
elseif order==2, condition = {'+','hard','easy','easy','hard','+','easy','hard','hard','easy','+','hard','easy','easy','hard','+'};
else;  error('order must be 1 or 2');
end

HideCursor

try
    %Prepare fullscreen window
    screens = Screen('Screens');
    screenNumber = max(screens);  %Highest screen number is most likely correct display
    [w, rect] = Screen('OpenWindow', screenNumber,128);
    ifi = Screen('GetFlipInterval', w);
    [x0,y0] = RectCenter(rect);

    textSize=round(x0/10);
    Screen('TextFont', w, 'Arial Unicode MS');    Screen('TextSize', w, textSize);
    textRect = Screen('TextBounds', w, '+');
    [xFixMid,yFixMid] = RectCenter(textRect);

    %Draw "waiting for trigger" screen
    instructions='Waiting for scanner...';
    textRect = Screen('TextBounds', w, instructions);
    [xTextMid,yTextMid] = RectCenter(textRect);
    Screen('DrawText', w, instructions , x0-xTextMid, y0-yTextMid, 255);
    Screen('Flip', w);

    [~, ~, keyCode] = KbCheck;
    while ( ~keyCode(KbName('t')) )
        [~, ~, keyCode] = KbCheck;
    end

    tStart=GetSecs(); tic   %start timing the exerpiment
    for blocknum = 1:length(condition)

        if condition{blocknum}=='+'
            Screen('DrawText', w, '+', x0-xFixMid, y0-yFixMid, 255);
            lastTime = Screen('Flip', w, nextTime);
            blockEnd=blockEnd+fixBlockLength;
            nextTime = tStart+blockEnd;
            while GetSecs()<nextTime-ifi
                [~, ~, keyCode] = KbCheck;
                assert(~keyCode(KbName('ESCAPE')),onExit);
            end
        else
            blockEnd=blockEnd+trialBlockLength;
            for trialnum = 1:trials

                rownum=rownum+1;

                %Initial Fixation (for one trial)
                if fixtime>0  %don't display fixation screen if fixtime = 0
                    Screen('DrawText', w, '+', x0-xFixMid, y0-yFixMid, 255);
                    lastTime = Screen('Flip', w, nextTime);
                    nextTime = lastTime + fixtime;
                end

                %Generate data and such
                %(A lot of this complexity is just for randomization purposes...)
                shape = GenShape(condition{blocknum});
                if strcmp(condition{blocknum}, 'easy')
                    ind = find(shape); %indices of all '1's in the shape
                    i = ceil(4*rand()); %pick a random square
                    first = ind(i); %the index of the chosen square
                    ind(i) = [];
                    ind = ind(randperm(3));
                    dispOrder = first; %dispOrder will contain the order in which to display the squares
                    i = 1;
                    while length(dispOrder) < 4
                            for j = randperm(length(dispOrder))  %loop through already displayed squares in random order
                                if isAdj( [3,4], ind(i), dispOrder(j) )
                                    dispOrder(end+1) = ind(i);
                                    ind(i) = [];
                                    i = 0;
                                    break  %stops the for-loop
                                end
                            end
                            i = i+1;
                    end
                else  %hard condition

                    %if the two starting squares can't result in a proper display, keep searching until a good starting pair is found
                    done = false;
                    while ~done
                        done = true;  %the loop will terminate after 1 iteration unless done is set to false

                        ind = find(shape); %indices of all the '1's in the shape
                        i = ceil(8*rand()); %pick a random square
                        first = ind(i); %the index of the chosen square (will be one of the two squares in the first screen)
                        ind(i) = [];
                        ind = ind(randperm(7));  %scramble indices
                        %find square adjacent to the first square
                        for n = 1:7
                            if isAdj( [3,4], first, ind(n) )
                                second = ind(n);
                                ind(n) = [];
                                break
                            end
                        end
                        %NOW: first = index of square 1 (for first screen)
                        %     second = index of square 2 (for first screen)
                        %     ind = list of remaining indices to be displayed (6 of them)

                        clear dispOrder %this needs to be done if the large while-loop has more than 1 iteration...
                        dispOrder(1,:) = [first, second];  %pairs of INDICES to be displayed (note: indices are NOT row/col pairs!)
                        i = 1;
                        flag = true;  %this is 'true' if the loops have not located any squares yet
                        while numel(dispOrder) < 8
                            if i > length(ind)  %presentation algorithm is impossible for this shape/starting pair combination
                                done = false;
                                break
                            end
                            %search through previously displayed squares for a square adjacent to ind(i)
                            for j = randperm(numel(dispOrder))
                                if isAdj( [3,4], ind(i), dispOrder(j) )
                                    if flag == true
                                        temp = ind(i);
                                        flag = false;
                                    else
                                        dispOrder(end+1,:) = [temp, ind(i)];
                                        flag = true;
                                    end
                                    ind(i) = [];
                                    i = 0;
                                    break  %stops the for-loop
                                end
                            end
                            i = i+1;
                        end

                    end  %way-outer while-loop

                end  %end if statement


                for n = 1:4
                    %display grid
                    tempfill = zeros(3,4);
                    if strcmp(condition{blocknum}, 'easy')
                        tempfill( dispOrder(n) ) = 1;
                    else
                        tempfill( dispOrder(n,:) ) = 1;
                    end

                    DrawGrid(w, x0, y0, 100, tempfill);
                    lastTime = Screen('Flip', w, nextTime);
                    nextTime = lastTime + prestime;

                end

                %pick sides for correct and fake answer
                if rand < 0.5
                    correctAns1 = KbName('1');
                    correctAns2 = KbName('1!');
                    correctWidth =    x0/2;
                    fakeWidth   = 3*x0/2;
                    fakeAns1 = KbName('2');%('2');
                    fakeAns2 = KbName('2@');%('2@');
                else
                    correctAns1 = KbName('2');%('2');
                    correctAns2 = KbName('2@');%('2@');
                    correctWidth = 3*x0/2;
                    fakeWidth   =     x0/2;
                    fakeAns1 = KbName('1');
                    fakeAns2 = KbName('1!');
                end

                if rand < .5  %fake answer deviates by 1 square
                    fakeshape = GenFakeAns(shape);
                else  %or by 2 squares
                    done = false;
                    while ~done
                        fakeshape = GenFakeAns(GenFakeAns(shape));
                        if ~isequal(shape, fakeshape), done = true; end
                    end
                end

                %show question screen
                DrawGrid(w, correctWidth, y0, 100, shape);
                DrawGrid(w,    fakeWidth, y0, 100, fakeshape);
                lastTime = Screen('Flip', w, nextTime);
                nextTime = (tStart+blockEnd-trialBlockLength)+(trialLength*trialnum); %starting time of next fixation screen

                Screen('DrawText', w, '.', 100, 100, [100 100 100 255]); %This line may or may not be necessary to eliminate weird lag

                %store some data
                subjData{rownum,1} = sessionID;
                subjData{rownum,2} = rownum; %"trial number" for purposes of output file
                subjData{rownum,3} = condition{blocknum};
                subjData{rownum,4} = 'na';
                subjData{rownum,5} = 'nr';
                subjData{rownum,6} = 'nr';
                subjData{rownum,7} = num2str(shape(:)');
                subjData{rownum,8} = num2str(fakeshape(:)');
                feedback = 9473*ones(1,4); fbColor=[64 0 0];  % sad face

                %get answer
                while GetSecs() < nextTime - feedbacktime
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(correctAns1) || keyCode(correctAns2)
                        feedback = 10004;   fbColor=[0 128 0];
                        subjData{rownum,5} = 1;
                        subjData{rownum,6} = GetSecs() - lastTime;
                        break
                    elseif keyCode(fakeAns1) || keyCode(fakeAns2)
                        feedback = 10008;  fbColor=[128 0 0];
                        subjData{rownum,5} = 0;
                        subjData{rownum,6} = GetSecs() - lastTime;
                        break
                    elseif keyCode(KbName('ESCAPE'))
                        assert(~keyCode(KbName('ESCAPE')),onExit);
                    end
                end

                % prepare user feedback
                Screen('TextSize', w, textSize*3);
                textRect = Screen('TextBounds', w, feedback);
                [xTextMid,yTextMid] = RectCenter(textRect);
                Screen('DrawText', w, feedback, x0-xTextMid, y0-yTextMid, fbColor);
                Screen('TextSize', w, textSize);

                % write subject data for this trial
                if feedback==9473
                    fprintf(dataFile,'%s \t%d \t%s \t%s \t%s \t%s \t%s \t%s \n',subjData{rownum,:});
                else
                    fprintf(dataFile,'%s \t%d \t%s \t%s \t%d \t%1.4f \t%s \t%s \n',subjData{rownum,:});
                end

                Screen('Flip', w);  % give feedback

            end%trial loop
        end
    end %block loop

    fprintf('Total elapsed time for this run: %3.5f\n', toc)

    cd(rootDir);
    ShowCursor
    fclose(dataFile);
    Screen('CloseAll');
catch
    %Save whatever data was gathered...
    cd(rootDir);
    fclose(dataFile);
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end



function TF = isAdj( dims, ind1, ind2 )
%checks to see if the positions ind1 and ind2 are adjacent in matrix M and returns true or false accordingly
[i1,j1] = ind2sub(dims, ind1);
[i2,j2] = ind2sub(dims, ind2);
if     i1 == i2 && abs(j1-j2) == 1, TF = true;
elseif j1 == j2 && abs(i1-i2) == 1, TF = true;
else;  TF = false;
end



function S = GenShape( difficulty )
%Generates and returns 3x4 matrix corresponding to the final shape: 0 means not filled, 1 means filled.
%Total number of filled squares for easy = 4, for hard = 8
S = zeros(3,4);
if strcmp(difficulty,'easy'), numsquares = 4; else; numsquares = 8; end
while Validate(S) == false
    S = zeros(3,4);
    while sum(sum(S)) < numsquares
        m = ceil(3*rand);
        n = ceil(4*rand);
        S(m,n) = 1;
    end
end


function isValid = Validate( S )
%Returns true if there is one group of adjacent '1's
if isequal(zeros(3,4), S)
    isValid = false;
    return
end
[i,j] = find(S, 1, 'first');  %only need one '1' to start the Tag function
T = Tag(S,i,j);
if isequal(zeros(3,4), S+T), isValid = true;
else;                        isValid = false;
end


function T = Tag( S, i, j )
%NOTE:  S(i,j) MUST equal 1.  This will not work correctly if it does not.
%recursively tags all stones in an adjacent group, starting with position S(i,j)
%'tagging' means changing each 1 to a -1;  function returns the tagged grid
S(i,j) = -1;
T = S;
if i > 1 && T(i-1,j)==1, T=Tag(T,i-1,j); %north
end
if i < 3 && T(i+1,j) ==1, T=Tag(T,i+1,j); %south
end
if j > 1 && T(i,j-1)==1, T=Tag(T,i,j-1); %west
end
if j < 4 && T(i,j+1)==1, T=Tag(T,i,j+1); %east
end


function F = GenFakeAns( S )
%Generates fake answer based on final shape.  Differs by 1 square from original
done = false; %I'm simulating a DO-WHILE loop here...
while ~done
    F = S;
    [i,j] = find(S); %pick random '1' to remove (turn to '0')
    n = ceil( length(i)*rand );
    F(i(n),j(n)) = 0;
    [i,j] = find(S == 0); %find all zeros in S (doesn't include the newly created zero in F)
    while 1 %loop breaks when an appropriate position has been found to alter the shape
        n = ceil( length(i)*rand );
        try if F(i(n)-1,j(n)) == 1; break; end; catch; 0; end
        try if F(i(n)+1,j(n)) == 1; break; end; catch; 0; end
        try if F(i(n),j(n)-1) == 1; break; end; catch; 0; end
        try if F(i(n),j(n)+1) == 1; break; end; catch; 0; end
    end
    F(i(n),j(n)) = 1;
    if Validate(F) == true, done = true; end
end


function DrawGrid( window, x, y, d, F )
%Draws a 3-by-4 grid of squares centered at (x,y). 'd' is side-length of each square
%F is a matrix which specifies which square(s) to fill

topleft = [x-2*d, y-1.5*d];  %of box
bottomright = [x+2*d, y+1.5*d];  %of box

%Fill area with white
Screen('FillRect', window, [255 255 255], [topleft, bottomright]);
%fill squares (before drawing gridlines)
for row = 1:3
    for col = 1:4
        if F(row,col) == 1
            %[x+(col-3)*d, y+(row-2.5)*d, x+(col-2)*d, y+(row-1.5)*d]
            Screen( 'FillRect', window, [0 0 255], [x+(col-3)*d, y+(row-2.5)*d, x+(col-2)*d, y+(row-1.5)*d] )
        end
    end
end

%draw frame
Screen('FrameRect', window , [0 0 0 255], [topleft, bottomright], 2);
%Draw 3 vertical gridlines
Screen('DrawLine', window, [0 0 0 255], x-d, topleft(2), x-d, bottomright(2), 2);
Screen('DrawLine', window, [0 0 0 255], x, topleft(2), x, bottomright(2), 2);
Screen('DrawLine', window, [0 0 0 255], x+d, topleft(2), x+d, bottomright(2), 2);
%Draw 2 horizontal gridlines
Screen('DrawLine', window, [0 0 0 255], topleft(1), y-0.5*d, bottomright(1), y-0.5*d, 2);
Screen('DrawLine', window, [0 0 0 255], topleft(1), y+0.5*d, bottomright(1), y+0.5*d, 2);
