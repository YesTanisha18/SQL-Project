CREATE TABLE IPL_Matches
(id	bigint,city varchar,date date,player_of_match varchar,venue varchar,neutral_venue int,team1 varchar,
 team2 varchar,toss_winner varchar,toss_decision varchar,winner varchar,result varchar,result_margin int,
 eliminator varchar,method varchar,umpire1 varchar,umpire2 varchar);
 
select * from ipl_matches; 
ALTER TABLE IPL_MATCHES ADD PRIMARY KEY(ID);

CREATE TABLE IPL_Ball
(id bigint PRIMARY KEY,inning int,over int,ball int,batsman varchar,non_striker varchar,bowler varchar,
 batsman_runs int,extra_runs int,total_runs int,is_wicket int,dismissal_kind varchar,player_dismissed varchar,	
 fielder varchar,extras_type varchar,batting_team varchar,bowling_team varchar);

select * from ipl_ball;

COPY IPL_Matches FROM 'C:\Program Files\PostgreSQL\15\data\Dataset\IPL Dataset\IPL_matches.csv' DELIMITER ',' CSV HEADER;
SET DATESTYLE TO "ISO, DMY";

select * from ipl_matches;

COPY IPL_Ball FROM 'C:\Program Files\PostgreSQL\15\data\Dataset\IPL Dataset\IPL_Ball.csv' DELIMITER ',' CSV HEADER;

select * from ipl_ball order by id;
select distinct batsman,count(ball) from ipl_ball group by batsman having count(ball)>500 order by count(ball) desc;
select distinct batsman,sum(batsman_runs) from ipl_ball group by batsman order by sum(batsman_runs) desc;

select player_of_match,count(distinct extract(year from date)) as no_of_seasons from ipl_matches 
group by player_of_match having count(distinct extract(year from date))>2;

select batsman,count(distinct id)/14 as no_of_seasons from ipl_ball
group by batsman having (count(distinct id)/14)>2;




--Aggressive batsmen(type 1)
select batsman as aggressive_batsmen,
count(ball) as balls_faced,
sum(batsman_runs) as total_runs,
round(sum(batsman_runs)*1.0/count(ball)*100,2) as strike_rate
from ipl_ball where not extras_type='wides' 
group by batsman having count(ball)>=500 
order by strike_rate desc limit 10;

--Anchor batsmen(type 2)
select batsman as anchor_batsmen,
sum(batsman_runs) as total_runs,
sum(is_wicket) as times_dismissed,
round(sum(batsman_runs)*1.0/sum(is_wicket),2) as average
from ipl_ball group by batsman 
having (count(distinct id))/14>2 and sum(is_wicket)>0 
order by average desc limit 10;

--Hard-hitter batsmen(type 3)

SELECT batsman as hard_hitting_batsmen,
SUM(Batsman_Runs) AS Total_Runs,
SUM(CASE 
	WHEN Batsman_Runs = 4 OR Batsman_Runs = 6 THEN Batsman_Runs 
	ELSE 0 
	END) AS Boundary_Runs,
ROUND((SUM(CASE 
		   WHEN Batsman_Runs = 4 OR Batsman_Runs = 6 THEN Batsman_Runs 
		   ELSE 0 END)*1.0/SUM(Batsman_Runs))*100,2) 
		   AS Boundary_Percentage
FROM IPL_Ball group by batsman 
having (count(distinct id)/14)>2
order by boundary_percentage desc 
limit 10;



--Economical bowlers(type 1)
select bowler as economical_bowlers,
sum(total_runs) as total_runs,
count(bowler)/6 as overs_bowled,
round(sum(total_runs)/(count(bowler)/6.0),2) as economy
from ipl_ball group by bowler 
having count(ball)>=500 order by economy asc 
limit 10;

--Wicket-taking bowlers(type 2)
select bowler as wicket_taking_bowlers,
count(ball) as balls_bowled,
sum(is_wicket) as wickets_taken,
round(count(ball)*1.0/sum(is_wicket),2) as strike_rate 
from ipl_ball
where dismissal_kind not in ('run out','retired hurt','obstructing the field')
group by bowler having count(ball)>=500
order by strike_rate asc limit 10;

--All-rounders
select a.batsman as all_rounders,
round(sum(a.batsman_runs)*1.0/count(a.ball)*100,2) as batting_strike_rate,
b.bowling_strike_rate from ipl_ball as a 
inner join
(select bowler,
 round(count(ball)*1.0/sum(is_wicket),2) as bowling_strike_rate 
 from ipl_ball
 where dismissal_kind not in ('run out','retired hurt','obstructing the field')
 group by bowler having count(ball)>=300
 order by bowling_strike_rate asc) as b
on a.batsman=b.bowler
where not extras_type='wides' 
group by batsman,bowling_strike_rate 
having count(a.ball)>=500
order by batting_strike_rate desc,bowling_strike_rate desc
limit 10;

--Wicket-keepers
select fielder as wicket_keepers,sum(is_wicket) as dismissals from ipl_ball
where dismissal_kind in ('stumped')
group by fielder order by dismissals desc limit 10;

'caught',

--Additional questions
--1
select count(distinct city) as ipl_city from ipl_matches;


CREATE TABLE Deliveries
(id bigint,inning int,over int,ball int,batsman varchar,non_striker varchar,
 bowler varchar,batsman_runs int,extra_runs int,total_runs int,
 is_wicket int,dismissal_kind varchar,player_dismissed varchar,	
 fielder varchar,extras_type varchar,batting_team varchar,
 bowling_team varchar);

select * from Deliveries; 

COPY Deliveries FROM 'C:\Program Files\PostgreSQL\15\data\Dataset\IPL Dataset\IPL_Ball.csv' 
DELIMITER ',' CSV HEADER;

--2
SELECT *, CASE
            WHEN total_runs>=4 THEN 'boundary'
			WHEN total_runs=0 THEN 'dot'
			ELSE 'other'
			END AS ball_result
FROM Deliveries;

CREATE TABLE deliveries_v02 AS (SELECT *, CASE WHEN total_runs>=4 THEN 'boundary'
												WHEN total_runs=0 THEN 'dot'
												ELSE 'other'
												END AS ball_result
									   FROM Deliveries);
   
select * from deliveries_v02; 

--3
select ball_result,count(ball_result) as no_of_balls 
from deliveries_v02 where ball_result in ('boundary','dot')
group by ball_result;

--4
select batting_team as team,
count(ball_result) as total_boundaries
from deliveries_v02 where ball_result='boundary' 
group by batting_team 
order by total_boundaries desc;

--5
select bowling_team as team,
count(ball_result) as total_dots 
from deliveries_v02 where ball_result='dot' 
group by bowling_team 
order by total_dots desc; --funnel chart

--6
select dismissal_kind,count(dismissal_kind) as total_dismissals
from deliveries_v02 
where not dismissal_kind='NA'
group by dismissal_kind
order by total_dismissals desc;

--7
select bowler,sum(extra_runs) as extra_runs_conceded
from deliveries where not extra_runs=0 
group by bowler order by extra_runs_conceded desc limit 5;

--8
CREATE TABLE matches AS SELECT * FROM ipl_matches;
select * from matches;

select a.*,b.venue as venue,b.date as match_date
from deliveries_v02 as a
left join
matches as b
on a.id=b.id;

CREATE TABLE deliveries_v03 AS (select a.*,b.venue as venue,b.date as match_date
		from deliveries_v02 as a
		left join matches as b
		on a.id=b.id);

select * from deliveries_v03;

--9
select venue,sum(total_runs) as total_runs_scored
from deliveries_v03
group by venue 
order by total_runs_scored desc;

--10
select extract(year from match_date) as year,
sum(total_runs) as total_runs_scored from deliveries_v03
where venue='Eden Gardens'
group by year order by total_runs_scored desc;
