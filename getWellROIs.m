function wells = getWellROIs(expDate,session,dilutionFactor)

% extract ROI identifiers for each dilution series. Rows are progressive serial dilutions, columns are replicates.
if expDate == 20190307
    if strcmp(session,'am')
        if dilutionFactor == 10
            wells = [6 1 3; 22 24 23];
        elseif dilutionFactor == 4
            wells = [8 9 7; 15 17 14; 26 27 30; 36 34 39];
        elseif dilutionFactor == 2
            wells = [5 4 2; 10 11 12; 16 18 13; 21 20 19; 25 28 29; 31 32 33; 35 37 38];
        end
    elseif strcmp(session,'pm')
        if dilutionFactor == 10
            wells = [1 2 3; 22 23 24; 43 45 40];
        elseif dilutionFactor == 4
            wells = [4 6 8; 16 17 18; 28 29 30; 39 35 38];
        elseif dilutionFactor == 2
            wells = [5 9 7; 11 10 12; 14 15 13; 21 20 19; 25 26 27; 33 31 32; 34 36 37; 41 44 42];
        end
    end
elseif expDate == 20190312
    if strcmp(session,'am')
        if dilutionFactor == 10
            wells = [11,7,12; 23,24,22];
        elseif dilutionFactor == 4
            wells = [15,18,17;9,10,6;26,28,27;38,39,37];
        elseif dilutionFactor == 2
            wells = [16,14,13;3,1,2;8,5,4;19,20,21;29,25,30;31,32,33;35,36,34];
        end
    elseif strcmp(session,'pm')
        if dilutionFactor == 10
            wells = [1,2,3;22,24,23];
        elseif dilutionFactor == 4
            wells = [4,5,6;18,17,16;30,28,29;39,37,38];
        elseif dilutionFactor == 2
            wells = [8,9,7;10,11,12;13,14,15;20,21,19;27,25,26;32,31,33;35,36,34];
        end
    end
elseif expDate == 20190320
    if strcmp(session,'am')
        if dilutionFactor == 10
            wells = [12,11,9;23,22,24];
        elseif dilutionFactor == 4
            wells = [10,8,7;18,16,15;30,28,29;39,31,37];
        elseif dilutionFactor == 2
            wells = [5,3,1;6,2,4;17,13,14;21,20,19;27,26,25;34,33,32;36,38,35];
        end
    elseif strcmp(session,'pm')
        if dilutionFactor == 10
            wells = [1,2,3;22,23,24];
        elseif dilutionFactor == 4
            wells = [4,5,7;15,17,18;30,28,29];
        elseif dilutionFactor == 2
            wells = [6,9,8;10,12,11;13,16,14;19,21,20;27,25,26;33,32,31];
        end
    end
elseif expDate == 20191126
    if strcmp(session,'pm')
        if dilutionFactor ==2
            wells = [13,14,15;1,4,6;5,3,2;9,7,8;12,11,10;18,16,17;20,21,19];
        end
    end
end
end