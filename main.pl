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


% The entry rule
query(ListOfKeywords) :- 
    findall(Title, session(Title, _), Titles),						% Get all titles in a list
	findall(SubjectList, session(_, SubjectList), SubjectLists),	% Get all Subject lists in a list
    
	get_keyword_weight_pairs(ListOfKeywords, ProcessedKeywords),	
	get_session_scores(Titles, SubjectLists, ProcessedKeywords, Scores),

	sort_by_score(Titles, Scores, SortedTitles, SortedScores),
	print_formatted(SortedTitles, SortedScores).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% SECTION: PARSE KEYWORDS %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Repeat until the given list is empty
get_keyword_weight_pairs([], []).
% Convert the keyword list given by the user to the full list of weighted keywords that need to be searched
get_keyword_weight_pairs([Keyword|ListOfKeywords], ProcessedKeywords) :- 
    get_keyword_weight_pairs(ListOfKeywords, TempList),
    parse(Keyword, ProcessedKeyword),                   
    append(TempList, ProcessedKeyword, ProcessedKeywords).

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
    add_weight_to_sub_keywords(SubKeywordList, SubWeight, SubKeywords).

% Repeat until there are no remaining keywords to be added
add_weight_to_sub_keywords([], _, []).
% Recursively add all sub keywords to a list
add_weight_to_sub_keywords([Keyword|Keywords], Weight, WeightedKeywords) :-
    add_weight_to_sub_keywords(Keywords, Weight, TempList),
    % Combine phrase and weiTemp
    pairs_keys_values([WeightedKeyword], [Keyword], [Weight]),
	append([WeightedKeyword], TempList, WeightedKeywords).

% Convert a given keyword to a list of itself and all sub keywords with their respective weights
parse(Keyword, [FullKeyword|SubKeywords]) :- 
    ensure_full_keyword(Keyword, FullKeyword),
    get_sub_keywords(FullKeyword, SubKeywords).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% SECTION: SCORE CALCULATION %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if a keyword exists in a title or subject of a session
% If it exists - return the score of the keyword
is_in_session(Input, KeywordPair, Score) :-
	pairs_keys_values([KeywordPair], [Keyword], [Score]),			% Seperate keyword and score          
	sub_string(case_insensitive, Keyword, Input).					% Check if keyword is in title or subject
	
% If it doesn't exist - return 0
is_in_session(Input, KeywordPair, 0) :-
	pairs_keys([KeywordPair], [Keyword]),							% Seperate keyword and score		
	\+ sub_string(case_insensitive, Keyword, Input),				% Check if keyword is not in title or subject
	!.																% Prevent unnecessary second pass

% Calculate the score associated with the subject of a session
get_subject_score(_, [], 0).
get_subject_score(Subject, [KeywordPair|RemainingKeywordPairs], Score):-
	get_subject_score(Subject, RemainingKeywordPairs, RemainingScore),
	is_in_session(Subject, KeywordPair, SubjectScore),				% Check if keyword is contained in the subject
	Score is SubjectScore + RemainingScore.							% Add the subject score

% Calculate the scores associated with the subjects of a session and store them in a list
get_subject_scores_list([], _, []).
get_subject_scores_list([Subject|RemainingSubjects], KeywordPairs, Scores):-
	get_subject_scores_list(RemainingSubjects, KeywordPairs, TempScores),
	get_subject_score(Subject, KeywordPairs, SubjectScore),
	append([SubjectScore], TempScores, Scores).						% Add the subject score in the subject scores list

% Calculate the total score of a session
get_session_score(Title, Subjects, KeywordPairs, TotalScore):-
	get_subject_scores_list(Subjects, KeywordPairs, SubjectScores),
	get_subject_score(Title, KeywordPairs, TitleScore),

	DoubleTitleScore is 2 * TitleScore,								% Title score counts as double
	append([DoubleTitleScore], SubjectScores, Scores),				% Add the title score to the subject scores list

	sum_list(Scores, ScoreSum),										% Sum the new list of scores
	max_list(Scores, MaxScore),										% Find the max individual score
	TotalScore is (1000 * MaxScore) + ScoreSum.						% Apply the session score formula

% Calculate the total score of all sessions and store them in a list
get_session_scores([], [], _, []).
get_session_scores([Title|RemainingTitles], [SessionSubjects|RemainingSessionSubjects], KeywordPairs, TotalScores):-
	get_session_scores(RemainingTitles, RemainingSessionSubjects, KeywordPairs, TempScores),
	get_session_score(Title, SessionSubjects, KeywordPairs, SessionScore),
	append([SessionScore], TempScores, TotalScores),				% Add the session score in the session scores list
	!.																% Prevent unnecessary second pass



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% SECTION: DISPLAY RESULTS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get a list of key-value pairs (title - score) and sort in descending order by score
sort_by_score(Titles, Scores, SortedTitles, SortedScores) :-
	pairs_keys_values(TitleScorePairs, Titles, Scores),				% Pair titles with their session scores

	transpose_pairs(TitleScorePairs, TempList),						% Flip the key-value pairs into value-key pairs and sort by score in ascending order
	reverse(TempList, SortedPairs),									% Reverse to sort in descending order
	
	pairs_keys_values(SortedPairs, SortedScores, SortedTitles).		% Separate lists

% Print the results in the requested format
print_formatted([], []).
print_formatted([Title|RemainingTitles], [Score|RemainingScores]):-
	write(' Session: '),
	write(Title), nl,
	write('	Relevance = '),
	write(Score), nl,
	print_formatted(RemainingTitles, RemainingScores).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% SECTION: SESSIONS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

session('Rules; Semantic Technology; and Cross-Industry Standards',
	['XBRL - Extensible Business Reporting Language',
	 'MISMO - Mortgage Industry Standards Maintenance Org',
	 'FIXatdl - FIX Algorithmic Trading Definition Language',
	 'FpML - Financial products Markup Language',
	 'HL7 - Health Level 7',
	 'Acord - Association for Cooperative Operations Research and Development (Insurance Industry)',
	 'Rules for Governance; Risk; and Compliance (GRC); eg; rules for internal audit; SOX compliance; enterprise risk management (ERM); operational risk; etc',
	 'Rules and Corporate Actions']).
session('Rule Transformation and Extraction',
	['Transformation and extraction with rule standards; such as SBVR; RIF and OCL',
	 'Extraction of rules from code',
	 'Transformation and extraction in the context of frameworks such as KDM (Knowledge Discovery meta-model)',
	 'Extraction of rules from natural language',
	 'Transformation or rules from one dialect into another']).
session('Rules and Uncertainty',
	['Languages for the formalization of uncertainty rules',
	 'Probabilistic; fuzzy and other rule frameworks for reasoning with uncertain or incomplete information',
	 'Handling inconsistent or disparate rules using uncertainty',
	 'Uncertainty extensions of event processing rules; business rules; reactive rules; causal rules; derivation rules; association rules; or transformation rules']).
session('Rules and Norms',
	['Methodologies for modeling regulations using both ontologies and rules',
	 'Defeasibility and norms - modeling rule exceptions and priority relations among rules',
	 'The relationship between rules and legal argumentation schemes',
	 'Rule language requirements for the isomorphic modeling of legislation',
	 'Rule based inference mechanism for legal reasoning',
	 'E-contracting and automated negotiations with rule-based declarative strategies']).
session('Rules and Inferencing',
	['From rules to FOL to modal logics',
	 'Rule-based non-monotonic reasoning',
	 'Rule-based reasoning with modalities',
	 'Deontic rule-based reasoning',
	 'Temporal rule-based reasoning',
	 'Priorities handling in rule-based systems',
	 'Defeasible reasoning',
	 'Rule-based reasoning about context and its use in smart environments',
	 'Combination of rules and ontologies',
	 'Modularity']).
session('Rule-based Event Processing and Reaction Rules',
	['Reaction rule languages and engines (production rules; ECA rules; logic event action formalisms; vocabularies/ontologies)',
	 'State management approaches and frameworks',
	 'Concurrency control and scalability',
	 'Event and action definition; detection; consumption; termination; lifecycle management',
	 'Dynamic rule-based workflows and intelligent event processing (rule-based CEP)',
	 'Non-functional requirements; use of annotations; metadata to capture those',
	 'Design time and execution time aspects of rule-based (Semantic) Business Processes Modeling and Management',
	 'Practical and business aspects of rule-based (Semantic) Business Process Management (business scenarios; case studies; use cases etc)']).
session('Rule-Based Distributed/Multi-Agent Systems',
	['rule-based specification and verification of Distributed/Multi-Agent Systems',
	 'rule-based distributed reasoning and problem solving',
	 'rule-based agent architectures',
	 'rules and ontologies for semantic agents',
	 'rule-based interaction protocols for multi-agent systems',
	 'rules for service-oriented computing (discovery; composition; etc)',
	 'rule-based cooperation; coordination and argumentation in multi-agent systems',
	 'rule-based e-contracting and negotiation strategies in multi-agent systems',
	 'rule interchange and reasoning interoperation in heterogeneous Distributed/Multi-Agent Systems']).
session('General Introduction to Rules',
	['Rules and ontologies',
	 'Execution models; rule engines; and environments',
	 'Graphical processing; modeling and rendering of rules']).
session('RuleML-2010 Challenge',
	['benchmarks/evaluations; demos; case studies; use cases; experience reports; best practice solutions (design patterns; reference architectures; models)',
	 'rule-based implementations; tools; applications; demonstrations engineering methods',
	 'implementations of rule standards (RuleML; RIF; SBVR; PRR; rule-based Event Processing languages; BPMN and rules; BPEL and rules); rules and industrial standards (XBRL; MISMO; Accord) and industrial problem statements',
	 'Modelling Rules in the Temporal and Geospatial Applications',
	 'temporal modelling and reasoning; geospatial modelling and reasoning',
	 'cross-linking between temporal and geospatial knowledge',
	 'visualization of rules with graphic models in order to support end-user interaction',
	 'Demos related to various Rules topics',
	 'Extensions and implementations of W3C RIF',
	 'Editing environments and IDEs for Web rules',
	 'Benchmarks and comparison results for rule engines',
	 'Distributed rule bases and rule services',
	 'Reports on industrial experience about rule systems']).