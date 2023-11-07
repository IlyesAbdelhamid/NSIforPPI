%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB Script Documentation
% Author: Ilyes Abdelhamid, 2023
% Description: This MATLAB script generates seperately the list of protein
% in the positve set and negative set from the existing results 
% %
% OUTPUT
% Positive and Negative set text files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cd './data/scripts/'

disp('Option 1: Running positive set creation');
tic;
create_positive_set_Yeast_DIP;
elapsed_time = toc;
disp(['Elapsed time for creating positive set: ', num2str(elapsed_time), ' s']);

disp('Option 1: Running negative set creation');
tic;
create_negative_set_Yeast_DIP;
elapsed_time = toc;
disp(['Elapsed time for creating negative set: ', num2str(elapsed_time), ' s']);

   