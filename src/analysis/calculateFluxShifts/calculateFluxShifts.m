function calculateFluxShifts(source, target)
% Compares reaction flux values (min, max) between two models or more models
% in resultsPostOptimization\contextSpecificModels folder and writes the
% comparison results ('up', 'down', 1) in a new column in the target model
%
% USAGE:
%
%   calculateFluxShifts(source, target)
%
% INPUTS:
%   source:                 model strusture
%   target:                 model strusture or a string value "All" when
%                           comparing all models in the folder resultsPostOptimization\contextSpecificModels 
%                           to the souce
%
% .. Authors:
%       - Kristina Grausa 05/16/2022
%       - Kristina Grausa 08/23/2022 - standard header and formatting
    
    % Get target model/-s
    destTarget = {};
    if string(target) == "All"
        destTarget = string(strcat('resultsPostOptimization\contextSpecificModels\*.xls'));
    else
        destTarget = string(strcat('resultsPostOptimization\contextSpecificModels\*',char(target),'*.xls'));
    end
    T = dir(destTarget);

    % Source model
    destSource = string(strcat('resultsPostOptimization\contextSpecificModels\*',char(source),'*.xls'));
    S = dir(destSource);
    sheetName = 'Reaction List';
    filename = strcat(S.folder, '\', S.name);
    dataSource=readtable(filename,'Sheet',sheetName);

    % Get minFlux and MaxFlux columns from source model
    minFluxSource = dataSource.MinFlux;
    maxFluxSource = dataSource.MaxFlux;

    % Create and fill cell arrays (min, max) with rounded flux values from source model
    minFluxSource_r = cell(height(dataSource), 1);
    maxFluxSource_r = cell(height(dataSource), 1);

    for i=1:1:height(minFluxSource_r)
        minFluxSource_r{i} = round(str2double(minFluxSource{i}),6);
        maxFluxSource_r{i} = round(str2double(maxFluxSource{i}),6);
    end

    % Get min and max flux data from target model file
    for i=1:1:length(T)
        if ~contains(T(i).name,char(source))

            filename = strcat(T(i).folder, '\', T(i).name);
            data=readtable(filename,'Sheet',sheetName);

            try
            % Get minFlux and MaxFlux columns from target model file
            minFlux = data.MinFlux;
            maxFlux = data.MaxFlux;

            % Create and fill cell arrays (min, max) with rounded flux
            % values from target model
            minFlux_r = cell(height(minFlux),1);
            maxFlux_r = cell(height(maxFlux),1);

            for k=1:1:height(data)
                minFlux_r{k} = round(str2double(minFlux{k}),6);
                maxFlux_r{k} = round(str2double(maxFlux{k}),6);
            end

            % Create and fill flux ratio cell arrays (target/source)
            MinFluxRatio = cell(height(minFlux),1);
            MaxFluxRatio = cell(height(minFlux),1);

            % Calculate ratios for all reaction fluxes
            for n=1:1:length(minFlux)
                minRatio = minFlux_r{n}/minFluxSource_r{n};
                maxRatio = maxFlux_r{n}/maxFluxSource_r{n};
                minRatio = round(minRatio,6);
                maxRatio = round(maxRatio,6);

                % Source flux is 0
                if minFluxSource_r{n} == 0 && minFlux_r{n} ~= 0
                    minRatio = 'up';
                end
                if maxFluxSource_r{n} == 0 && maxFlux_r{n} ~= 0
                    maxRatio = 'up';
                end

                % Target flux is 0
                if minFlux_r{n} == 0 &&  minFluxSource_r{n} ~= 0
                    minRatio = 'down';
                end
                if maxFlux_r{n} == 0 && maxFluxSource_r{n} ~= 0
                    maxRatio = 'down';
                end

                % Both are 0
                if minFlux_r{n} == 0 &&  minFluxSource_r{n} == 0
                    minRatio = 1;
                end
                if maxFlux_r{n} == 0 && maxFluxSource_r{n} == 0
                    maxRatio = 1;
                end

                MinFluxRatio{n} = minRatio;
                MaxFluxRatio{n} = maxRatio;
            end
            
            % Save results
            folderName = 'resultsPostOptimization\fluxShifts\';
            if ~exist(folderName, 'dir')
               mkdir(folderName)
            end

            ratioData = cell2table([minFluxSource_r, maxFluxSource_r, MinFluxRatio, MaxFluxRatio]);
            ratioData.Properties.VariableNames = {strcat('MinFlux_',source{1}), strcat('MaxFlux_',source{1}), 'MinFluxRatio', 'MaxFluxRatio'};
            newData = [data ratioData];
            
            temp = split(T(i).name,".");
            resultFileName = strcat(temp(1),'_flux_shifts.xls');
            fullResultFilePath = strcat(folderName, resultFileName);
            writetable(newData,fullResultFilePath{1},'AutoFitWidth',false);
            catch e
                disp(e);
            end
        end
    end
end
