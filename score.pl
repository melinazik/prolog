% parameters: input - title or subject of session
%             keyword - keyword to check
%             points - list of points 
% 
% return: points of keyword if kewyord is found in session
%         0 otherwise
is_in_session(Input, Keyword, Points, Score):-
	sub_string(case_insensitive, Keyword, Input),
	Score is Points,
	!.

is_in_session(Input, Keyword, Points, Score):-
    \+(sub_string(case_insensitive, Keyword, Input)),
    Score is 0,
    !.


% parameters: title - the title of a session
%             list 1 - list of keywords
%             list 2 - list of points 
% 
% return: score associated with the title  
title_score(_, [], [], 0).
title_score(Title, [Head1|Tail1], [Head2|Tail2], Score):-
	title_score(Title, Tail1, Tail2, RemainingScore),
	is_in_session(Title, Head1, Head2, TitleScore),
	Score is TitleScore * 2 + RemainingScore.


% parameters: subject - the subject of a session
%             list 1 - list of keywords
%             list 2 - list of points 
% 
% return: list with subject scores of a session
subject_score(_, [], [], 0).
subject_score(Subject, [Head1|Tail1], [Head2|Tail2], Score):-
	subject_score(Subject, Tail1, Tail2, RemainingScore),
	is_in_session(Subject, Head1, Head2, SubjectScore),
	Score is SubjectScore + RemainingScore.


% parameters: list 1 - session subjects
%             list 2 - list of keywords
%             list 3 - list of points 
% 
% return: list of scores associated with the subject  
subject_total_score([], _, _, []).
subject_total_score([Head1|Tail1], Keywords, Points, Score):-
	subject_total_score(Tail1, Keywords, Points, RemainingScore),
	subject_score(Head1, Keywords, Points, SubjectScore),
	append([SubjectScore], RemainingScore, Score).


% parameters: Title - session title
%             Subjects - list of session subjects
%             Keywords - list of keywords
%             Points - list of keyword points
% 
% return: total score of session which is 1000 * Max + Sum
session_score(Title, Subjects, Keywords, Points, TotalScore):-
	title_score(Title, Keywords, Points, TitleScore),
	subject_total_score(Subjects, Keywords, Points, SubjectScore),
	append([TitleScore], SubjectScore, Score),
	sum_list(Score, Sum),
	max_list(Score, Max),
	TotalScore is 1000 * Max + Sum.


% parameters: list 1 - list of session titles
%             list 2 - list of session subjects
%             Keywords - list of keywords
%             Points - list of keyword points
% 
% return: list with total scores of all sessions
score([], [], _, _, []).
score([Head1|Tail1], [Head2|Tail2], Keywords, Points, TotalScore):-
	score(Tail1, Tail2, Keywords, Points, RemainingScore),
	session_score(Head1, Head2, Keywords, Points, SessionScore),
	append([SessionScore], RemainingScore, TotalScore),
	!.
