function maturities = getMaturitiesJK(variableNames)
    % Define the mapping for maturities
    maturitiesDict = dictionary;
    
    % Populate the mapping for Fed Funds futures
    maturitiesDict("FF1") = 1/12;
    maturitiesDict("FF2") = 2/12;
    maturitiesDict("FF3") = 3/12;
    maturitiesDict("FF4") = 4/12;
    maturitiesDict("MP1") = 1/12;
    
    % Populate the mapping for Eurodollar futures
    maturitiesDict("ED1") = 1/4;
    maturitiesDict("ED2") = 2/4;
    maturitiesDict("ED3") = 3/4;
    maturitiesDict("ED4") = 1;
    
    % Populate the mapping for Treasury futures
    maturitiesDict("TFUT02") = 2;
    maturitiesDict("TFUT05") = 5;
    maturitiesDict("TFUT10") = 10;
    maturitiesDict("TFUT30") = 15;

    % Initialize output array
    N = length(variableNames);
    maturities = nan(1, N); % Default to NaN if variable name is not found
    
    % Loop through each variable name and get its maturity
    for i = 1:N
        if isKey(maturitiesDict, variableNames{i})
            maturities(i) = maturitiesDict(variableNames{i});
        end
    end
end