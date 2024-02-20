/* Work ing on the null values*/

/* --------Bowler Queries-------- */

-- Top 10 Most Wickets Taken in IPL History
SELECT TOP 10 bowler, COUNT(wicket_type) as Wickets
FROM CricketData.dbo.match_data
WHERE wicket_type IS NOT NULL AND wicket_type NOT LIKE 'run out'
GROUP BY bowler
ORDER BY Wickets DESC

-- Top 10 Dot Balls Bowled in IPL History
SELECT TOP 10 bowler, COUNT(ball) as DotBalls
FROM CricketData.dbo.match_data
WHERE runs_off_bat = 0 AND extras = 0
GROUP BY bowler
ORDER BY DotBalls DESC

-- Top 10 Most Extras Bowled in IPL History
SELECT TOP 10 bowler, COUNT(extras) as Extras
FROM CricketData.dbo.match_data
WHERE extras >= 1
GROUP BY bowler
ORDER BY Extras DESC

-- TOP 10 Most Maidens in IPL history
SELECT bowler, (count(ball)/6) as oversBowled, SUM(runs_off_bat) OVER(PARTITION BY oversBowled) as RunsPerOver
FROM CricketData.dbo.match_data
GROUP BY bowler
ORDER BY oversBowled DESC

--Every Bowler Ball
SELECT bowler,cast(round(ball,1) AS STRING)
FROM CricketData.dbo.match_data

SELECT bowler, count(ball) , runs_off_bat
FROM CricketData.dbo.match_data
GROUP BY bowler,runs_off_bat

-- Most "Expensive Bowlers" in IPL History
SELECT TOP 10 bowler, Count(ball) as BoundaryBalls, count(DISTINCT match_id) as NumGames
FROM CricketData.dbo.match_data
WHERE runs_off_bat >= 4
GROUP BY bowler
ORDER BY BoundaryBalls DESC

-- Idea: Use Partion by Overs to get maidens per over

--Runs for each over grouped by bowler



/* --------Batsmen Queries-------- */


-- Top 10 Most Runs Scored in IPL History
SELECT TOP 10 striker, SUM(runs_off_bat) as TotalRuns, COUNT(ball) as BallsFaced 
FROM CricketData.dbo.match_data
GROUP BY striker
ORDER BY TotalRuns DESC

-- Top 10 Batsmen with Most Sixes in IPL History
SELECT TOP 10 striker, count(runs_off_bat) as Sixes
FROM CricketData.dbo.match_data
WHERE runs_off_bat = 6
GROUP BY striker
ORDER BY Sixes DESC

-- Top 10 Batsmen with Most Fours in IPL History
SELECT TOP 10 striker, count(runs_off_bat) as Fours
FROM CricketData.dbo.match_data
WHERE runs_off_bat = 4
GROUP BY striker
ORDER BY Fours DESC

-- Top 10 Most Boundaries in IPL history
SELECT TOP 10 striker, count(runs_off_bat) as BoundaryRunsOnly
FROM CricketData.dbo.match_data
WHERE runs_off_bat > 3
GROUP BY striker
ORDER BY BoundaryRunsOnly DESC

-- Top 10 Batsmen with Most Non Boundary Runs in IPL History
SELECT TOP 10 striker, count(runs_off_bat) as NonBoundaryRuns
FROM CricketData.dbo.match_data
WHERE runs_off_bat < 4
GROUP by striker
ORDER by NonBoundaryRuns DESC

--Top 10 Highest Single Match Scores in IPL History
WITH RunsPerGame as(
	SELECT striker,sum(runs_off_bat) as runs,COUNT(DISTINCT match_id) as GamesPlayed, count(ball) as ballsfaced
	FROM CricketData.dbo.match_data
	GROUP BY striker, match_id
) SELECT TOP 10 RunsPerGame.striker, MAX(RunsPerGame.runs) as MostRunsInAGame, RunsPerGame.ballsfaced
FROM RunsPerGame
GROUP BY striker, runs, ballsfaced
ORDER BY runs DESC

--Strike Rate When Chasing vs Setting

-- Detemining Chasing
SELECT striker, count(runs_off_bat)as RunsChasing
FROM CricketData.dbo.match_data as MatchData
JOIN CricketData.dbo.match_info_data as MatchInfo
	ON MatchData.cricsheet_id = MatchInfo.id
--Ensure strikers is batting in the second innings "Chase innings"
WHERE innings = 2
GROUP BY striker
ORDER BY RunsChasing DESC

/* Team Stats Stuff*/

-- Team Wins All Time
SELECT winner, count(winner) as Wins
FROM CricketData.dbo.match_info_data
GROUP BY winner
ORDER BY Wins Desc
--Issue: Teams that changed names and onership would have to ammend win totals. Hostory of the teamswould need to eb taken into account

--Top 5 Most Runs in and innings by Team

-- ISNULL used becuase null values exist in the columns of each of the extras

SELECT TOP 5 MD.batting_team as team, MD.season, SUM(MD.runs_off_bat + ISNULL(noballs,0) + ISNULL(wides,0) + ISNULL(legbyes,0) + ISNULL(byes,0)) as TotalRuns, MI.winner as MatchWinner, MD.innings as BattingInnings
FROM CricketData.dbo.match_data as MD
JOIN CricketData.dbo.match_info_data as MI
	ON  MD.cricsheet_id = MI.id
GROUP BY MD.cricsheet_id, MD.batting_team,MD.season, MI.winner, MD.innings
ORDER BY TotalRuns DESC

--Top 5 Quickest Innings Endings - Incomplete
SELECT count(wicket_type) as wickets, bowling_team, innings, sum(runs_off_bat + noballs + wides + legbyes + byes) as runsscored
FROM CricketData.dbo.match_data
WHERE innings < 3 --where condition used to filter out annomalies wehre the innings was greater that 2
GROUP BY innings, bowling_team,cricsheet_id
ORDER BY wickets DESC, runsscored ASC

--Join To Count Wins by the team when they were chasing - Incomplete
SELECT DISTINCT winner, count(winner)
FROM CricketData.dbo.match_data as MatchData
INNER JOIN CricketData.dbo.match_info_data as MatchInfo
	ON MatchData.cricsheet_id = MatchInfo.id
WHERE innings = 2 AND batting_team = winner --Batting insecond innings is Chasing
GROUP BY winner