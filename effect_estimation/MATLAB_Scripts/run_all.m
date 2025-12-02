% Define the values for a and b
a_values = {'language', 'MD', 'DMN'};
b_values = 1:7;

% Loop over all combinations and run them sequentially
for i = 1:length(a_values)
    for j = b_values
        fprintf('Running mROI_mega_all(%s, %d)\n', a_values{i}, j);
        mROI_mega_all(a_values{i}, j);
    end
end
