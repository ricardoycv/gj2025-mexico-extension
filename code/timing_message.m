function msg = timing_message(it, nalldraws, dt_start)
% PURPOSE: Prepare timing message
% INPUTS:
% it - number of draw/iteration
% nalldraws - total number of draws/iteratins
% dt_start - start of the drawing/iteratins, 
%       obtained as dt_start = now; or dt_start = datetime('now');
% OUTPUT:
% msg - string, message about time elapsed, remaining, estimate of the end
% Marek Jarocinski
if isfloat(dt_start)
    dt_start = datetime(dt_start,'ConvertFrom','datenum');
end
dur_elapsed = datetime('now') - dt_start;
dur_total = dur_elapsed*nalldraws/it;
dur_remain = dur_total - dur_elapsed;
dt_end = datetime('now') + dur_remain;
msg_elapsed = "elapsed " + string(dur_elapsed);
msg_remain = "remain " + string(dur_remain,"dd:hh:mm:ss");
msg_end = "end " + string(dt_end);
msg = msg_elapsed + "; " + msg_remain + "; " + msg_end;
end
