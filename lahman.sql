/* 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names 
	  as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. 
	  Which Vanderbilt player earned the most money in the majors? */

SELECT 
	DISTINCT namefirst || ' ' || namelast AS name, 
	SUM(salary) OVER(PARTITION BY playerid) AS salary
FROM people
LEFT JOIN salaries
USING(playerid)
LEFT JOIN collegeplaying
USING(playerid)
WHERE schoolid = 'vandy' AND salary IS NOT null
ORDER BY salary DESC;

-- David Price



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
GROUP BY pos



/* 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
	  Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the 
	  **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, 
	  check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) */
	  
WITH
	bins AS (
	SELECT 
		generate_series(1920, 2016, 10) AS lower,
		generate_series(1930, 2030, 10) AS upper
	),
	query AS (
	SELECT 
		DISTINCT yearid, 
		SUM(g) OVER(PARTITION BY yearid) AS games_played, 
		SUM(so) OVER(PARTITION BY yearid) strikeouts 
	FROM teams
	)



/* 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage 
	  of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) 
	  Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage. */

SELECT 
	namefirst || ' ' || namelast AS name,
	sb AS stolen_bases,
	sb + cs AS attempts,
	ROUND(sb::numeric / (sb::numeric + cs::numeric), 2) AS stolen_base_pct
FROM batting
LEFT JOIN people
USING(playerid)
WHERE yearid = 2016 AND sb >= 20
ORDER BY stolen_base_pct DESC; 

-- Chris Owings



/* 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
	  What is the smallest number of wins for a team that did win the world series? Doing this will probably result 
	  in an unusually small number of wins for a world series champion; determine why this is the case. 
	  Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with 
	  the most wins also won the world series? What percentage of the time? */







