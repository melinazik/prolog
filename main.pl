% Odysseas Lomvardeas 3362
% Alexandros Sofoulakis 3346
% Melina Zikou 3357

% IMPROVEMENT: The program detects words containing dashes (-) as a single word in all circumstances.
% For example, the keyword 'semi-transparent'-4 is a single keyword with weight 4, 
% but the keyword 'semi-transparent glass'-4 is 3 keywords: 
% 
% 1) 'semi-transparent glass' with weight 4
% 2) 'semi-transparent' with weight 2
% 3) 'glass' with weight 2

query(ListOfKeywords) :- generate_keyword_score_pairs(ListOfKeywords, [], ProcessedList), print(ProcessedList).

% Final step to pass the list to the output variable
generate_keyword_score_pairs([], ProcessedList, ProcessedList).
% Convert the keyword list given by the user to the full list of weighted keywords that need to be searched
generate_keyword_score_pairs([Keyword|ListOfKeywords], PreviousList, ProcessedList) :- 
    parse(Keyword, ProcessedKeyword),                   
    append(PreviousList, ProcessedKeyword, NewList),
    % Repeat until the given list is empty
    generate_keyword_score_pairs(ListOfKeywords, NewList, ProcessedList).

% Keyword matches the pattern keyword-weight
ensure_full_keyword(Keyword, Keyword) :- 
    pairs_keys_values([Keyword], _, [Weight]),
    number(Weight),                                                 % Required for words with dashes (eg. semi-transparent)
    !.                                                              % Prevent unnecessary second pass

% Keyword lacks weight
ensure_full_keyword(Keyword, FullKeyword) :- 
    \+ (
        pairs_keys_values([Keyword], _, [Weight]),
        number(Weight)                                              % Required for words with dashes (eg. semi-transparent)
    ),                   
    pairs_keys_values([FullKeyword], [Keyword], [1]).               % Add default weight (1)

% Keyword is a single word
get_sub_keywords(Keyword, []) :-
    pairs_keys([Keyword], [UnweightedKeyword]),                     % Get phrase
    \+ sub_string(case_insensitive, ' ', UnweightedKeyword),        % Phrase is a single word with no whitespace
    !.                                                              % Prevent unnecessary second pass

% Keyword is a phrase
get_sub_keywords(Keyword, SubKeywords) :-
    pairs_keys([Keyword], [UnweightedKeyword]),                     % Get phrase
    pairs_values([Keyword], [Weight]),                              % Get weight
    
    atomic_list_concat(SubKeywordList, ' ', UnweightedKeyword),     % Detect whitespace and split to a list of words
    length(SubKeywordList, NumberOfKeywords),                       % Find number of words in phrase
    
    SubWeight is Weight/NumberOfKeywords,                           % Calculate weight of words
    add_weight_to_sub_keywords(SubKeywordList, SubWeight, [], SubKeywords).

% Final step to pass the list to the output variable
add_weight_to_sub_keywords([], _, WeightedKeywords, WeightedKeywords).
% Recursively add all sub keywords to a list
add_weight_to_sub_keywords([Keyword|Keywords], Weight, PreviousList, WeightedKeywords) :-
    pairs_keys_values([WeightedKeyword], [Keyword], [Weight]),
    % Repeat until there are no remaining keywords to be added
    add_weight_to_sub_keywords(Keywords, Weight, [WeightedKeyword|PreviousList], WeightedKeywords).

% Convert a given keyword to a list of itself and all sub keywords with their respective weights
parse(Keyword, [FullKeyword|SubKeywords]) :- 
    ensure_full_keyword(Keyword, FullKeyword),
    get_sub_keywords(FullKeyword, SubKeywords).