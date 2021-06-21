## University Project on Prolog - Conference Session Assistant


Creation of a program - an assistant to a computer scientist who wishes to submit a paper to a scientific conference. The conference is separated in more specific sessions. Each session has a distinct theme consisting of the general title and the subjects that will be presented in the session. A scientist who wants to submit a paper to the conference will be asked to choose one of the sessions based on their work. The program - assistant will take as input some keywords that describe the subject of their work and will suggest in descending order the most relevant sessions along with the corresponding score relativity.

## Execution
1. Download SWI-PL from https://www.swi-prolog.org/.
2. Compile main.pl with swipl.
```
swipl main.pl
```
3. Type the query with the List Of Keywords. For example,
```
?- query(['rule exception', 'Challenge'-3, 'interaction protocols'-7]).
```
