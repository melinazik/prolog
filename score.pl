% parameters: input - title or subject of session
%             keywordPairs - keyword pairs(word - values)
% 
% return: points of keyword if kewyord is found in session
%         0 otherwise
is_in_session(_, [], 0).
is_in_session(Input, [Head|_], Score):-
	pairs_keys([Head], [Keyword]),
	pairs_values([Head], [Points]),
	sub_string(case_insensitive, Keyword , Input),
	Score is Points,
	!.

is_in_session(_, [], 0).
is_in_session(Input, [Head|_], Score):-
	pairs_keys([Head], [Keyword]),
	\+(sub_string(case_insensitive, Keyword , Input))
	Score is 0,
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
%             list  - keyword pairs(word - values)
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
subject_total_score([], [], _, 0).
session_score(Title, Subjects, KeywordPairs, TotalScore):-
	title_score(Title, KeywordPairs, TitleScore),
	subject_total_score(Subjects, KeywordPairs, SubjectScore),
	append([TitleScore], SubjectScore, Score),
	sum_list(Score, Sum),
	max_list(Score, Max),
	TotalScore is 1000 * Max + Sum.


% parameters: list 1 - list of session titles
%             list 2 - list of session subjects
%             list  - keyword pairs(word - values)
% 
% return: list with total scores of all sessions
score([], [], _, []).
score([Head1|Tail1], [Head2|Tail2], KeywordPairs, TotalScore):-
	score(Tail1, Tail2, KeywordPairs, RemainingScore),
	session_score(Head1, Head2, KeywordPairs, SessionScore),
	append([SessionScore], RemainingScore, TotalScore),
	!.
