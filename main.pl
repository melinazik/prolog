% Odysseas Lomvardeas 3362
% Alexandros Sofoulakis 3346
% Melina Zikou 3357

query(ListOfKeywords) :- generate_keyword_score_pairs(ListOfKeywords, [], ProcessedList), print(ProcessedList).

% Convert the keyword list given by the user to the full list of weighted keywords that need to be searched
generate_keyword_score_pairs([], PreviousList, ProcessedList) :- ProcessedList = PreviousList.
generate_keyword_score_pairs([Keyword|ListOfKeywords], PreviousList, ProcessedList) :- 
    parse(Keyword, ProcessedKeyword),                   
    append(PreviousList, ProcessedKeyword, NewList),
    % Repeat until the given list is empty
    generate_keyword_score_pairs(ListOfKeywords, NewList, ProcessedList).

% Keyword matches the pattern keyword-weight
ensure_full_keyword(Keyword, Keyword) :- 
    pairs_keys_values([Keyword], [_], [Weight]),
    number(Weight),                                     % Required for words with dashes (eg. semi-transparent)
    !.                                                  % Prevent unnecessary second pass

% Keyword lacks weight
ensure_full_keyword(Keyword, FullKeyword) :- 
    \+ (
        pairs_keys_values([Keyword], [_], [Weight]),
        number(Weight)                                  % Required for words with dashes (eg. semi-transparent)
    ),                   
    pairs_keys_values([FullKeyword], [Keyword], [1]).   % Add default weight (1)

% Keyword is a single word
get_sub_keywords(Keyword, []) :-
    pairs_keys([Keyword], [UnweightedKeyword]),
    \+ sub_string(case_insensitive, ' ', UnweightedKeyword).

% Keyword is a phrase
get_sub_keywords(Keyword, SubKeywords) :-
    pairs_keys([Keyword], [UnweightedKeyword]),         % Get phrase
    pairs_values([Keyword], [Weight]),                  % Get weight
    
    sub_string(case_insensitive, ' ', UnweightedKeyword),
    atomic_list_concat(SubKeywordList, ' ', UnweightedKeyword),
    length(SubKeywordList, NumberOfKeywords),           % Find number of words in phrase
    
    SubWeight is Weight/NumberOfKeywords,               % Calculate weight of words
    add_weight_to_sub_keywords(SubKeywordList, SubWeight, [], SubKeywords).


add_weight_to_sub_keywords([], _, PreviousList, WeightedKeywords) :- WeightedKeywords = PreviousList.
add_weight_to_sub_keywords([Keyword|Keywords], Weight, PreviousList, WeightedKeywords) :-
    pairs_keys_values([WeightedKeyword], [Keyword], [Weight]),
    % Append new keyword to the sub keyword list
    append(PreviousList, [WeightedKeyword], NewList),
    % Repeat until there are no remaining keywords to be added
    add_weight_to_sub_keywords(Keywords, Weight, NewList, WeightedKeywords).

% Convert a given keyword to a list of itself and all sub keywords with their respective weights
parse(Keyword, ProcessedKeyword) :- 
    ensure_full_keyword(Keyword, FullKeyword),
    get_sub_keywords(FullKeyword, SubKeywords), 
    append([FullKeyword], SubKeywords, ProcessedKeyword).
    