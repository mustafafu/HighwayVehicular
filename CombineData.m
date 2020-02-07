%% Data Parser

datadir = '/data';
nRarr = 1:5;
hRarr = [1.5, 2, 3, 4, 5];


for NAI = 0:length(nRarr)*length(hRarr)-1
  hRidx = floor(mod(NAI,length(nRarr)*length(hRarr))/1/length(nRarr)) + 1;
  nRidx = mod(mod(NAI,length(nRarr)*length(hRarr)), length(nRarr)) + 1;
  hBs = hRarr(hRidx);  % BS antenna height (in meters) BS antenna height (in meters) 8->1 Lane 5->2 Lanes  2->3 Lanes
  numBs = nRarr(nRidx); % # of BSs in coverage area
  string_1 = [datadir, './numBS_',num2str(numBs),'-heightBS_',num2str(hBs)];
  string_1 = strrep(string_1,'.',',')
  matrix_list = dir(['.',string_1,'*'])
  if length(matrix_list) >0
    load(['.',datadir,'/',strtrim(matrix_list(1).name)]);
  else
      continue;
  end
  iter_size = size(durationIter,1);
  num_iter = size(matrix_list,1);
  CellDuration = cell(iter_size*num_iter,1);
  CellNumBlock = cell(iter_size*num_iter,1);
  CellProbability = cell(iter_size*num_iter,1);
  durationList = [];
  for jj=1:length(matrix_list)
    load(['.',datadir,'/',strtrim(matrix_list(jj).name)]);
    CellDuration(((jj-1)*iter_size +1):((jj)*iter_size),1) = durationIter;
    CellNumBlock(((jj-1)*iter_size +1):((jj)*iter_size),1) = numBlockIter;
    CellProbability(((jj-1)*iter_size +1):((jj)*iter_size),1) = probabilityIter;
    for i = 1:size(durationIter,1)
      durationList = [durationList cell2mat(durationIter(i))];
    end
  end
  NumBlock = cell2mat(CellNumBlock);
  Probability = cell2mat(CellProbability);
  CellNumBlock = 0;
  CellProbability =0;
  mkdir(['.',datadir,'/combined_data']);
  string_2 = [datadir,'/combined_data', '/combined-numBS_',num2str(numBs),'-heightBS_',num2str(hBs),'-Durations-Probabilities'];
  string_2 = strrep(string_2,'.',',');
  save(['.',string_2,'.mat'], 'NumBlock','Probability','CellDuration')
  string_3 = [datadir,'/combined_data','/combined-numBS_',num2str(numBs),'-heightBS_',num2str(hBs),'-DurationList'];
  string_3 = strrep(string_3,'.',',');
  save(['.',string_3,'.mat'], 'durationList')
end
