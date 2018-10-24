%IMPROVED MATLAB FILE PARSER- faster than the handout version, could be
%faster but I really don't see the point.
%Produces the following outputs:
%
%ATTRIBUTES:
%	Features of all of the examples. Each example is a row,
%	each feature a column. Nominal features are integers (a boolean feature
%	is just a nominal feature with two values), continuous features are
%	floating-point.
%
%CLASSIFICATIONS:
%	Classifications of all the examples. One big vector of boolean values,
%	in the same order as the attributes.
%
%TYPE_SIZES:
%	The total number of labels of all the nominal features (continuous
%	features have this value set to 0). Same order as the features in the
%	Attributes output.
%
%TYPE_NAMES:
%	The names of the features, if for some reason you want them.
function [ ATTRIBUTES, CLASSIFICATIONS, TYPE_SIZES, TYPE_NAMES ] = typed_parser( path )
	%Read the files.
	path_to_type = strcat(path, '.names');
	path_to_data = strcat(path, '.data');
	f_type = fopen(path_to_type);
	f_data = fopen(path_to_data);
	
	%Get info on the features themselves
	[TYPE_NAMES, type_codes, num_examples] = parse_typefile(f_type);
	fclose(f_type);
	
	ATTRIBUTES = zeros(num_examples, size(type_codes, 1));
	CLASSIFICATIONS = false(num_examples, 1);
	
	%Build the expression we will use to scan the entire file at once.
	regex_str = '%d ';
	for a = 1 : size(type_codes, 1)
		if(size(type_codes{a}, 1) == 0)
			regex_str = strcat(regex_str, '%n ');
		else
			regex_str = strcat(regex_str, '%s ');
		end
	end
	regex_str = strcat(regex_str, '%s');
	%Scan it in.
	big_cell = textscan(f_data, regex_str, 'Delimiter', ',');
	
	%Put the attributes in their proper places in the feature vector
	for b = 2 : size(big_cell, 2) - 1
		if(iscell(big_cell{b}(1)))
			for c = 1 : size(big_cell{b}, 1)
				ATTRIBUTES(c, b-1) = lookup_ind(big_cell{b}(c), type_codes{b-1});
			end
		else
			ATTRIBUTES(:, b-1) = big_cell{b};
		end
	end
	
	%Format the classification elements.
	stringed_classes = big_cell{size(big_cell, 2)};
	for c = 1 : size(stringed_classes)
		CLASSIFICATIONS(c, 1) = strcmp(stringed_classes(c, 1), '1');
	end
	
	TYPE_SIZES = zeros(size(TYPE_NAMES));
	for c = 1 : size(TYPE_SIZES, 1)
		TYPE_SIZES(c) = size(type_codes{c},1);
	end
end

function [TYPE_NAMES, TYPE_CODES, N_EXAMPLES] = parse_typefile(file_in)
	%The first line is the example classification, which is always 0,1 , so
	%we will just discard it.
	fgetl(file_in);
	
	%The 'index' line immediately following the classification line has the
	%useful property of showing us exactly how many examples will be in the
	%resulting data file, so we will go ahead and get that information now
	%even though we will only use it later.
	N_EXAMPLES = pmc(fgetl(file_in), ',') + 1;
	
	%Grab all of the information from inside of the file and split it into
	%the type name and information on the possible type values.
	cellified_string = textscan(file_in, '%s %s', 'Delimiter', ':');
	names_cell = cellified_string(1);
	value_cell = cellified_string(2);
	
	%The type names are already ready to go into their own matrix. Little
	%else needs to be done.
	TYPE_NAMES = names_cell{1};
	
	type_string_values = value_cell{1};
	tsv_size = size(type_string_values);
	TYPE_CODES = cell(tsv_size(1), 1);
	for n = 1:tsv_size(1)
		if(~strcmp(type_string_values(n), 'continuous.'))
			datastring = char(type_string_values(n));
			tsize = pmc(datastring, ',') + 1;
			TYPE_CODES{n} = cell(tsize, 1);
			ind = 1;
			build_string = '';
			for x = 1 : size(datastring, 2) - 1
				if(strcmp(datastring(1, x), ','))
					TYPE_CODES{n}{ind} = build_string;
					build_string = '';
					ind = ind + 1;
				else
					build_string = strcat(build_string, datastring(1, x));
				end
			end
			TYPE_CODES{n}{ind} = build_string;
		end
		%Otherwise, we are continuous and should leave the array empty.
	end
end

function [INDEX] = lookup_ind(candidate, name_list)
	for d = 1 : size(name_list, 1)
		if(strcmp(candidate, name_list{d}))
			INDEX = d;
			break
		end
	end
end

function [COUNT] = pmc(string_in, string_lookfor)
	total_number_size = size(strfind(string_in, string_lookfor));
	COUNT  = total_number_size(2);
end