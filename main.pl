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

% parameters: input - title or subject of session
%             keywordPairs - keyword pairs(word - values)
% 
% return: points of keyword if kewyord is found in session
%         0 

is_in_session(Input, FullKeyword, Score) :-
	pairs_keys_values([FullKeyword], [Keyword], [Score]),
	sub_string(case_insensitive, Keyword, Input),
	% print(Score), nl,
	!.

is_in_session(Input, FullKeyword, 0) :-
	pairs_keys([FullKeyword], [Keyword]),
	% print(Keyword),
	\+ sub_string(case_insensitive, Keyword, Input),
	% print(0), nl,
	!.

% parameters: title - the title of a session
%             list  - keyword pairs(word - values)
% 
% return: score associated with the title  
title_score(_, [], 0).
title_score(Title, [Head|Tail], Score):-
	title_score(Title, Tail, RemainingScore),
	is_in_session(Title, Head, TitleScore),
	Score is TitleScore * 2 + RemainingScore.


% parameters: subject - the subject of a session
%             list  - keyword pairs(word - values)
% 
% return: list with subject scores of a session
subject_score(_, [], 0).
subject_score(Subject, [Head|Tail], Score):-
	subject_score(Subject, Tail, RemainingScore),
	is_in_session(Subject, Head, SubjectScore),
	Score is SubjectScore + RemainingScore.


% parameters: list 1 - session subjects
%             list - keyword pairs(word - values)
% 
% return: list of scores associated with the subject  
subject_total_score([], _, []).
subject_total_score([Head|Tail], KeywordPairs, Score):-
	subject_total_score(Tail, KeywordPairs, RemainingScore),
	subject_score(Head, KeywordPairs, SubjectScore),
	append([SubjectScore], RemainingScore, Score).


% parameters: Title - session title
%             Subjects - list of session subjects
%             list  - keyword pairs(word - values)
% 
% return: total score of session which is 1000 * Max + Sum
session_score(Title, Subjects, KeywordPairs, TotalScore):-
	title_score(Title, KeywordPairs, TitleScore),
	subject_total_score(Subjects, KeywordPairs, SubjectScores),
	append([TitleScore], SubjectScores, Scores),
	sum_list(Scores, Sum),
	max_list(Scores, Max),
	TotalScore is 1000 * Max + Sum.


% parameters: list 1 - list of session titles
%             list 2 - list of session subjects
%             list  - keyword pairs(word - values)
% 
% return: list with total scores of all sessions
score([], [], _, []).
score([HeadTitle|TailTitle], [HeadSubject|TailSubject], KeywordPairs, TotalScores):-
	score(TailTitle, TailSubject, KeywordPairs, RemainingScores),
	session_score(HeadTitle, HeadSubject, KeywordPairs, SessionScore),
	append([SessionScore], RemainingScores, TotalScores),
	!.
