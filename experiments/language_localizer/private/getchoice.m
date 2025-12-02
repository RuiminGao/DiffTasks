function [resp, rt] = getchoice(opts, timeout, k)
% resp = response; rt = response time
% opts = options structure, timeout = how long to wait, k = key to wait for

%D = opts.D;
%while KbCheck(D); end % make sure no keys are depressed

start_time = GetSecs;
timeout = timeout + start_time;

success = false; resp = 0;
while ~success && GetSecs < timeout
    pressed = false;
    while ~pressed && GetSecs < timeout
        [pressed, ~, kbData] = KbCheck()
    end
        %for i = 1:length(opts.keycodes)
            if kbData(opts.keycodes(1)) == 1
                success = 1;
                resp = '1'
                rt = GetSecs - start_time
            elseif kbData(opts.keycodes(2)) == 1
                success = 1;
                resp = '2'
                rt = GetSecs - start_time
                %return;
            end
            rt = GetSecs - start_time
        end
    end


%rt = nan;

