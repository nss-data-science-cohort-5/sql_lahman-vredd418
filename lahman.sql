/* 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names 
	  as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. 
	  Which Vanderbilt player earned the most money in the majors? */

SELECT
	name,
	SUM(salary::numeric::money) AS salary
FROM
	(SELECT 
		DISTINCT namefirst || ' ' || namelast AS name,
		salary
	FROM people
	JOIN salaries
	USING(playerid)
	JOIN collegeplaying
	USING(playerid)
	WHERE schoolid = 'vandy' AND salary IS NOT null
	ORDER BY salary DESC) AS sub
GROUP BY name
ORDER BY salary DESC;

-- David Price

-- Ross's code
SELECT DISTINCT -- p.playerid,
	p.namefirst || ' ' || p.namelast AS playername,
--	cp.schoolid,
--	s.lgid,
	SUM(s.salary) AS total_salary
FROM people p
	INNER JOIN collegeplaying cp
		ON p.playerid = cp.playerid
	INNER JOIN salaries s
		ON p.playerid = s.playerid
WHERE cp.schoolid = 'vandy'
--	AND lgid = 'ML'	??
GROUP BY 1
ORDER BY 2 DESC;



/* 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
	  those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
	  Determine the number of putouts made by each of these three groups in 2016. */

SELECT 
	SUM(PO) as putouts,
	pos
FROM
	(SELECT
		PO,
		CASE WHEN pos = 'OF' THEN 'Outfield'
			 WHEN pos IN('SS', '1B', '2B', '3B') THEN 'Infield'
			 ELSE 'Battery' END AS pos
	FROM fielding
	WHERE yearid = 2016) AS sub
GROUP BY pos;

-- 41424	"Battery"
-- 58934	"Infield"
-- 29560	"Outfield"



/* 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
	  Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the 
	  **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, 
	  check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) */
	  
SELECT
	TRUNC(yearid::numeric, -1) AS decade,
	ROUND(SUM(so::numeric) / SUM(g::numeric), 2) AS so_per_game,
	ROUND(SUM(hr::numeric) / SUM(g::numeric), 2) AS hr_per_game
FROM teams
WHERE yearid::numeric >= 1920
GROUP BY decade
ORDER BY decade;



/* 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage 
	  of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) 
	  Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage. */

SELECT 
	namefirst || ' ' || namelast AS name,
	sb AS stolen_bases,
	sb + cs AS attempts,
	ROUND(sb::numeric / (sb::numeric + cs::numeric) * 100, 2) AS stolen_base_pct
FROM batting
LEFT JOIN people
USING(playerid)
WHERE yearid = 2016 AND (sb + cs) >= 20
ORDER BY stolen_base_pct DESC; 

-- Chris Owings

-- Should do it this way because players can play for different teams in the same season and this query accounts for that. 

WITH full_batting AS (
	SELECT
		playerid,
		SUM(sb) AS sb,
		SUM(cs) AS cs,
		SUM(sb) + SUM(cs) AS attempts
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
)
SELECT
	namefirst || ' ' || namelast AS name,
	sb,
	attempts,
	ROUND(sb * 100.0 / attempts, 3) AS sb_percentage
FROM full_batting
INNER JOIN people
USING (playerid)
WHERE attempts >= 20
ORDER BY sb_percentage DESC;



/* 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
	  What is the smallest number of wins for a team that did win the world series? Doing this will probably result 
	  in an unusually small number of wins for a world series champion; determine why this is the case. 
	  Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with 
	  the most wins also won the world series? What percentage of the time? */

SELECT MAX(w)
FROM teams
WHERE yearid::numeric BETWEEN 1970 AND 2016
AND wswin = 'N';

-- 116 wins

SELECT  MIN(w)
FROM teams
WHERE yearid::numeric BETWEEN 1970 AND 2016
AND wswin = 'Y' AND yearid != '1981';

-- 83 wins

WITH maxwins_each_year AS ( -- Get most wins in each season
	SELECT
		yearid,
		MAX(w) AS maxwins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	GROUP BY yearid
	ORDER BY yearid
),
	team_most_wins AS ( -- Add team name and wswin by joining on maxwins_each_year.maxwins = teams.w AND maxwins_each_year.yearid = teams.yearid
	SELECT
		maxwins_each_year.yearid,
		maxwins_each_year.maxwins,
		teams.name,
		teams.wswin
	FROM maxwins_each_year
	JOIN teams
	ON maxwins_each_year.maxwins = teams.w AND maxwins_each_year.yearid = teams.yearid
	)
SELECT 
	ROUND((SELECT COUNT(*) FROM team_most_wins WHERE wswin = 'Y') * 100.0 / (SELECT COUNT(*) FROM team_most_wins), 2); 

-- Michael's Answer

-- Ross's code
WITH cteYearWins AS
(
	SELECT DISTINCT yearid,
		MAX(W) AS maxwins,
		COUNT(*) OVER() AS maxwin_row_cnt
	FROM teams
	WHERE (yearid >= 1970
			AND yearid <= 2016)	
		AND yearid <> 1981	
	GROUP BY yearid
),
cteWSWins AS
(
	SELECT DISTINCT t.yearid,
		t.name,
		t.W,
		t.WSWin,
		cyw.maxwin_row_cnt AS maxwin_rows
	--	, cyw.maxwins
	FROM teams t
		INNER JOIN cteYearWins cyw
			ON t.yearid = cyw.yearid
			AND t.W = cyw.maxwins
	WHERE (t.yearid >= 1970
			AND t.yearid <= 2016)
		AND t.yearid <> 1981
		AND t.WSWin = 'Y'
--	GROUP BY 1, 2, 3, 4
	ORDER BY t.yearid
)
SELECT yearid,
	name,
	W,
	(100 * COUNT(*) OVER() / maxwin_rows) AS pct
FROM cteWSWins;



/* 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
	  Give their full name and the teams that they were managing when they won the award. */

WITH al AS (
	SELECT 
		playerid,
		yearid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'AL'
),
nl AS (
	SELECT
		playerid,
		yearid		
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid = 'NL'
)
SELECT 


-- Michael's code
WITH winning_managers AS (
	SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
	AND lgid IN ('AL', 'NL')
	GROUP BY playerid
	HAVING COUNT(DISTINCT lgid) = 2)
SELECT
	namefirst || ' ' || namelast AS manager_name,
	yearid,
	name
FROM awardsmanagers
INNER JOIN people
USING(playerid)
INNER JOIN managers
USING (playerid, yearid)
INNER JOIN teams
USING (teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
AND playerid IN (SELECT * FROM winning_managers)
ORDER BY manager_name, yearid;

-- Bryan's code
with winners as (
    select playerid,
           yearid,
           lgid,
           -- hack for counting distinct values in a window function
           -- https://www.sqlservercentral.com/forums/topic/how-to-distinct-count-with-windows-functions-i-e-over-and-partition-by
           -- the first dense_rank assigns a 1 to the first unique lgids then a 2 to the next unique lgid
           -- the second dense_rank reverses the order, assigning a 2 to the first unique lgid then a 2 to the next unique lgids
           -- subtracting 1 then makes all values equal across rows (in this case 2 since we're only dealing with two leagues)
           case when dense_rank() over(partition by playerid order by lgid) + dense_rank() over(partition by playerid order by lgid desc) - 1 = 2
               then true
               else false
               end as won_in_both_leagues
    from awardsmanagers
    where awardid = 'TSN Manager of the Year'
    and lgid in ('NL', 'AL')
),
 managed_teams as (
    select distinct m.playerid,
                    t2.franchname,
                    m.teamid,
                    m.yearid,
                    t.lgid,
                    tsn.won_in_both_leagues
    from managers m
    inner join winners tsn
    on tsn.playerid = m.playerid
    and tsn.yearid = m.yearid
    inner join teams t
    on t.teamid = m.teamid
    inner join teamsfranchises t2
    on t.franchid = t2.franchid
 )
select mt.playerid,
       concat(p.namefirst, ' ', p.namelast) as full_name,
       mt.franchname team_name,
       mt.yearid as year,
       case when mt.lgid = 'AL' then 'American' else 'National' end as league
from managed_teams as mt
inner join people as p
on p.playerid = mt.playerid
where mt.won_in_both_leagues = true
order by playerid desc;

/* 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). 
	  Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player. */  

WITH so AS(
	SELECT
		playerid,
		SUM(so) AS so
	FROM pitching
	WHERE yearid = 2016 AND gs >= 10
	GROUP BY playerid
	),
salary AS(
	SELECT
		playerid,
		SUM(salary) AS salary
		--salary
	FROM salaries
	WHERE yearid = 2016
	GROUP BY playerid
)
SELECT
	namefirst || ' ' || namelast AS name, 
	(salary / so)::numeric::money AS dollhairs_per_so
FROM so
JOIN salary
USING(playerid)
JOIN people
USING(playerid)
ORDER BY dollhairs_per_so DESC
LIMIT 1;
	
-- Matt Cain, this is possibly wrong, Ross and Connor got James Shields, Alex got Matt Cain


SELECT DISTINCT -- p.playerid,
	pl.namefirst || ' ' || pl.namelast AS playername,
--	pi.teamid,
--	SUM(pi.GS) AS games_started,
--	pi.yearid,
--	s.yearid,
	SUM(pi.so) AS strikeouts,
	SUM(s.salary)::numeric::money AS total_salary,
	SUM(s.salary)::numeric::money / SUM(pi.so) AS efficiency	-- IS THIS RIGHT?
FROM people pl
	INNER JOIN pitching pi
		ON pl.playerid = pi.playerid
	INNER JOIN salaries s
		ON pl.playerid = s.playerid
WHERE pi.yearid = 2016
	AND s.yearid = 2016
	AND pi.GS >= 10
GROUP BY 1
ORDER BY efficiency DESC;



/* 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, 
	  and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) 
	  Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.	*/

WITH
	hits AS (
	SELECT
		playerid,
		SUM(h) AS hits
	FROM batting
	GROUP BY playerid
	HAVING SUM(h) >= 3000
	)
SELECT
	DISTINCT namefirst || ' ' || namelast AS name,
	hits,
	CASE WHEN inducted = 'N' THEN NULL
		 ELSE halloffame.yearid END AS inducted
FROM hits
JOIN people
USING(playerid)
JOIN halloffame
USING(playerid);



/* 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names. */

SELECT 
	name
	--COUNT(name) AS count
FROM
	(SELECT 
			people.namefirst || ' ' || people.namelast AS NAME,
			teamid,
			SUM(h) AS hits
		FROM batting
		JOIN people
	 	USING(playerid)
		GROUP BY playerid, teamid, name
		HAVING SUM(h) >= 1000
		ORDER BY playerid) AS sub
GROUP BY name
HAVING COUNT(name) = 2;



/* 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played 
	  in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last 
	  names and the number of home runs they hit in 2016. */

WITH hr_by_season AS (
	SELECT
		playerid,
		people.namefirst || ' ' || people.namelast AS name,
		yearid,
		SUM(hr) OVER(PARTITION BY playerid, yearid) AS hr,
		COUNT(playerid) OVER(PARTITION BY playerid) AS years
	FROM batting
	LEFT JOIN people
	USING(playerid)
	),
	max_hr_by_season AS (
	SELECT
		playerid,
		MAX(hr) AS max_hr
	FROM hr_by_season
	GROUP BY playerid	
	)
SELECT 
	DISTINCT name -- used distinct because Bobby Wilson appears 3 times
FROM hr_by_season
JOIN max_hr_by_season
USING(playerid)
WHERE hr = max_hr AND yearid = 2016 AND years >= 10 AND hr >= 1;



-- Ways to answer #3

-- Convert yearid to timestamp by concating day-month-hr:mm:ss, then extract decade from it
SELECT 
	ROUND(AVG(SO / G), 2) AVG_SO_PER_G,
	EXTRACT(DECADE FROM CONCAT(YEARID, '-01-01 00:00:00')::TIMESTAMP) * 10 AS DECADE
FROM TEAMS
WHERE YEARID >= 1920
GROUP BY DECADE
ORDER BY DECADE;

-- Generate series
WITH 
	bins AS(
		SELECT generate_series(1920,2019, 10) AS lower,
			   generate_series(1929, 2019, 10) AS upper
	),
		   
	strikeouts AS (
		SELECT 
		yearid,
		SUM(so)/SUM(g)::numeric AS strikeouts_per_game
		FROM teams
		WHERE yearid >= 1920
		GROUP BY 1
		ORDER BY 1 desc
	)
SELECT 
	lower,
	upper, 
	ROUND(AVG(strikeouts_per_game), 2) AS strikeouts_per_game
FROM bins 
LEFT JOIN strikeouts
	ON strikeouts.yearid >= lower
	AND strikeouts.yearid <= upper
GROUP BY lower, upper
ORDER BY lower DESC;
	
-- Sum up all all strikeouts, in all games, for all teams, in each decade, then get avg
WITH so_hr_decades AS (
	SELECT 
		yearid,
		teamid,
		g,
		FLOOR(yearid/10)*10 AS decade,
		so,
		hr
	FROM teams
)
SELECT
	decade,
	ROUND(SUM(so)*2.0/(SUM(g)), 2) AS so_per_game,
	ROUND(SUM(hr)*2.0/(SUM(g)), 2) AS hr_per_game
FROM so_hr_decades
GROUP BY decade
ORDER BY decade;

-- Round years down to decade. Easy way to do this.
SELECT TRUNC(YEARID, -1) AS DECADE,
	ROUND(SUM(SO) * 2.0 / SUM(G), 2) AS STRIKEOUTS_PER_GAME,
	ROUND(SUM(HR) * 2.0 / SUM(G), 2) AS HOMERUNS_PER_GAME
FROM TEAMS
WHERE YEARID >= 1920
GROUP BY DECADE
ORDER BY DECADE;






