function ttabd = dt2d(ttabt, mydateName)
% PURPOSE: Aggregate data with multiple observations per day to daily by adding up.
% INPUTS:
% ttabt - table/timetable with potentially multiple observations per day
% mydateName - name of the date column that overrides the name of the time 
% OUTPUT:
% ttabd - table/timetable with daily data with one observation per day

arguments
    ttabt {mustBeA(ttabt, ["table", "timetable"])}
    mydateName string = ""
end

if isa(ttabt, 'table')
    dateName = ttabt.Properties.VariableNames{1};
    ttabt = table2timetable(ttabt);
    b_table = true;
elseif isa(ttabt, 'timetable')
    dateName = ttabt.Properties.DimensionNames{1};
    b_table = false;
else
    error('Please provide a table or a timetable')
end

if strlength(mydateName) > 0
    dateName = mydateName;
end

[~,N] = size(ttabt);

% all dates, unique dates
dates = dateshift(ttabt.(ttabt.Properties.DimensionNames{1}), "start", "day");
udates = unique(dates);
udates.Format = "uuuu-MM-dd";
Td = length(udates);

% Initialize the daily table
ttabd = timetable(udates, DimensionNames=[dateName,"Variables"]);
for n = 1:N
    varName = ttabt.Properties.VariableNames{n};
    varData = ttabt.(varName);    
    % Check the type of the variable and initialize accordingly
    if isnumeric(varData)
        % Initialize numeric variables with NaN
        ttabd.(varName) = NaN(Td, 1);
    elseif iscell(varData)
        % Initialize cell array variables with empty cells
        ttabd.(varName) = cell(Td, 1);
    else
        error('Unsupported variable type.');
    end
end

% Fill the daily table
for dd = 1:Td
    % Row selector
    row_numbers = dates == udates(dd);
    for nn = 1:N
        datarn = ttabt{row_numbers, nn};
        if iscell(datarn)
            ttabd{dd,nn} = {strjoin(datarn, ' + ')};
        elseif ~all(isnan(datarn))
            % if not all NaNs use sum(...,"omitnan") 
            % this changes NaN to 0
            ttabd{dd,nn} = sum(datarn, 1, "omitnan");
        end
    end
end

if b_table
    ttabd = timetable2table(ttabd);
end
