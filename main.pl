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

:- [sessions].

query(ListOfKeywords) :- 
    generate_keyword_score_pairs(ListOfKeywords, [], ProcessedList),
    findall(X, session(X,_), Titles),
	findall(Y, session(_,Y), Subjects),
	score(Titles, Subjects, ProcessedList, Scores),
	print(Scores).
	% print(ProcessedList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% SECTION: PARSE KEYWORDS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    \+ sub_string(case_insensitive, '\s', UnweightedKeyword),       % Phrase is a single word with no whitespace
    !.                                                              % Prevent unnecessary second pass

% Keyword is a phrase
get_sub_keywords(Keyword, SubKeywords) :-
    pairs_keys_values([Keyword], [UnweightedKeyword], [Weight]),    % Seperate phrase and weight
    
    split_string(UnweightedKeyword, '\s', '\s', SubKeywordList),    % Detect whitespace and split to a list of words
    length(SubKeywordList, NumberOfKeywords),                       % Find number of words in phrase
    
    SubWeight is Weight/NumberOfKeywords,                           % Calculate weight of words
    add_weight_to_sub_keywords(SubKeywordList, SubWeight, [], SubKeywords).

% Final step to pass the list to the output variable
add_weight_to_sub_keywords([], _, WeightedKeywords, WeightedKeywords).
% Recursively add all sub keywords to a list
add_weight_to_sub_keywords([Keyword|Keywords], Weight, PreviousList, WeightedKeywords) :-
    % Seperate phrase and weight
    pairs_keys_values([WeightedKeyword], [Keyword], [Weight]),
    % Repeat until there are no remaining keywords to be added
    add_weight_to_sub_keywords(Keywords, Weight, [WeightedKeyword|PreviousList], WeightedKeywords).

% Convert a given keyword to a list of itself and all sub keywords with their respective weights
parse(Keyword, [FullKeyword|SubKeywords]) :- 
    ensure_full_keyword(Keyword, FullKeyword),
    get_sub_keywords(FullKeyword, SubKeywords).





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% SECTION: SORT RESULTS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Gets Start_list, which is a list of key-value pairs (title-score) and sorts in descending order by score
% Returns separated titles and scores lists
sort_results(StartList, TitlesFinal, ScoresFinal) :-
	transpose_pairs(StartList, TempList),
	% transpose_pairs is bbuilt in swi-polog and flips the key-value pairs onto value-key pairs and sorts by value ascending order
	reverse(TempList, SortedList),
    %Now it is sorted in desc order
	pairs_values(SortedList, TitlesFinal),
	pairs_keys(SortedList, ScoresFinal). %Separate lists and return them


print_results([], []).
print_results([HeadTitles|TailTitles], [HeadScores|TailScores]):-
	write(' Session: '),
	write(HeadTitles), nl,
	write('	Score = '),
	write(HeadScores), nl,
	print_results(TailTitles, TailScores).





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% SECTION: SCORE CALCULATION %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if a keyword exists in a title or subject of a session
% If it exists - return the score of the keyword
	is_in_session(Input, FullKeyword, Score) :-
	pairs_keys_values([FullKeyword], [Keyword], [Score]),			% Seperate keyword and score          
	sub_string(case_insensitive, Keyword, Input),					% Check if keyword is in title or subject
	!.

% If it doesn't exist- return 0
is_in_session(Input, FullKeyword, 0) :-
	pairs_keys([FullKeyword], [Keyword]),							% Seperate keyword and score		
	\+ sub_string(case_insensitive, Keyword, Input),				% Check if keyword is not in title or subject
	!.


% Calculate the score associated with the title of a session
title_score(_, [], 0).
title_score(Title, [KeywordPair|RemainingKeywordPairs], Score):-
	title_score(Title, RemainingKeywordPairs, RemainingScore),		
	is_in_session(Title, KeywordPair, TitleScore),					% Check if keyword is in title
	Score is TitleScore * 2 + RemainingScore.						% Multiply the score of title * 2 (if the keyword is in the title)


% Calculate the score associated with the subject of a session
subject_score(_, [], 0).
subject_score(Subject, [KeywordPair|RemainingKeywordPairs], Score):-
	subject_score(Subject, RemainingKeywordPairs, RemainingScore),
	is_in_session(Subject, KeywordPair, SubjectScore),				% Check if keyword is in subject
	Score is SubjectScore + RemainingScore.							% Add the score of subject (if the keyword is in the subject)


% Calculate the scores associated with the subjects of a session and store them in a list
subject_total_score([], _, []).
subject_total_score([Subject|RemainingSubjects], KeywordPairs, Score):-
	subject_total_score(RemainingSubjects, KeywordPairs, RemainingScore),
	subject_score(Subject, KeywordPairs, SubjectScore),
	append([SubjectScore], RemainingScore, Score).					% Add to the list of subject scores the subject score


% Calculate the total score of session which is 1000 * Max + Sum
session_score(Title, Subjects, KeywordPairs, TotalScore):-
	title_score(Title, KeywordPairs, TitleScore),
	subject_total_score(Subjects, KeywordPairs, SubjectScores),
	append([TitleScore], SubjectScores, Scores),					% Add to the list of title scores the title score
	sum_list(Scores, Sum),											% Sum the list of scores
	max_list(Scores, Max),											% Find the max element of the list of scores
	TotalScore is 1000 * Max + Sum.									% Calculate the session score


% Calculate the total score of all sessions and store them in a list
score([], [], _, []).
score([Title|RemainingTitles], [SessionSubjects|RemainingSessionSubjects], KeywordPairs, TotalScores):-
	score(RemainingTitles, RemainingSessionSubjects, KeywordPairs, RemainingScores),
	session_score(Title, SessionSubjects, KeywordPairs, SessionScore),
	append([SessionScore], RemainingScores, TotalScores),
	!.
