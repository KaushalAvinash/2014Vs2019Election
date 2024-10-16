-- List top5/bottom5 constituencies of 2014 and 2019 in terms of voter turnout ratio

(select e2014.state as state, e2014.pc_name as constituency,
(sum(e2014.total_votes)/sum(e2014.total_electors))*100 as votes_turnout_ratio2014, 
(sum(e2019.total_votes)/sum(e2019.total_electors))*100 as votes_turnout_ratio2019, 'Top 5' as category
from e2014 join e2019
on e2014.pc_name = e2019.pc_name
and e2014.state = e2019.state
group by state, constituency
order by votes_turnout_ratio2014 asc , votes_turnout_ratio2019 asc
limit 5)
union
(select e2014.state as state, e2014.pc_name as constituency,
(sum(e2014.total_votes)/sum(e2014.total_electors))*100 as votes_turnout_ratio2014, 
(sum(e2019.total_votes)/sum(e2019.total_electors))*100 as votes_turnout_ratio2019, 'Bottom 5' as category
from e2014 join e2019
on e2014.pc_name = e2019.pc_name
and e2014.state = e2019.state
group by state, constituency
order by votes_turnout_ratio2014 desc, votes_turnout_ratio2019 desc
limit 5);


-- Which  constituencies have elected the same party for two consecutive, rank them by % of votes to that winning part in 2019.
WITH vote_percentages AS (
    SELECT e2014.pc_name, e2014.total_votes AS e2014_votes, e2014.party AS e2014_party,
           e2019.total_votes AS e2019_votes, e2019.party AS e2019_party,
           (e2014.total_votes + COALESCE(e2019.total_votes, 0)) AS total_votes_both,
           (e2019.total_votes * 100.0 / SUM(e2019.total_votes) OVER()) AS vote_percentage_2019
    FROM (SELECT e.pc_name, e.total_votes, e.party
          FROM e2014 e
          JOIN (
            SELECT pc_name, MAX(total_votes) AS max_votes
            FROM e2014
            GROUP BY pc_name
        ) AS max_results
        ON e.pc_name = max_results.pc_name AND e.total_votes = max_results.max_votes
    ) e2014
    LEFT JOIN (
        SELECT e.pc_name, e.total_votes, e.party
        FROM e2019 e
        JOIN (SELECT pc_name, MAX(total_votes) AS max_votes
             FROM e2019
             GROUP BY pc_name
        ) AS max_results
        ON e.pc_name = max_results.pc_name AND e.total_votes = max_results.max_votes
    ) e2019
    ON e2014.pc_name = e2019.pc_name
)
SELECT *, RANK() OVER (ORDER BY vote_percentage_2019 DESC) AS vote_rank_2019
FROM vote_percentages
WHERE e2014_party = e2019_party;



-- % Split of votes of parties between 2014 vs 2019 national level
SELECT party,
       (total2014 / SUM(total2014) OVER()) * 100 AS percent_total2014, 
       (total2019 / SUM(total2019) OVER()) * 100 AS percent_total2019
FROM (
    SELECT e2014.party AS party, 
           SUM(e2014.total_votes) AS total2014, 
           SUM(e2019.total_votes) AS total2019
    FROM e2014 
    JOIN e2019 ON e2014.pc_name = e2019.pc_name
    GROUP BY e2014.party
) AS t
ORDER BY total2014 DESC, total2019 DESC;



-- % Split of votes of parties between 2014 vs 2019 state level

select state, party,
(total2014 / SUM(total2014) over()) * 100 as percent_total2014, 
       (total2019 / SUM(total2019) over()) * 100 as percent_total2019
       from
(select e2014.state  as state , e2014.party as party , sum(e2014.total_votes) as total2014,
sum(e2019.total_votes) as total2019
from e2014 join e2019
on e2014.pc_name = e2019.pc_name
group by state, party
ORDER BY state)  as t
order by percent_total2014, percent_total2019; 


-- List top 5 constituencies for the two major national parties where they have gain votes share in 2019 as compared to 2014.
(select e2019.pc_name, e2019.party, (sum(e2019.total_votes) - sum(e2014.total_votes)) as diff
 from e2019
 join e2014
 on e2019.pc_name = e2014.pc_name
 where e2019.party = 'BJP'
 group by e2019.pc_name, e2019.party
 order by diff desc limit 5
)
UNION
(select e2019.pc_name, e2019.party, (sum(e2019.total_votes) - sum(e2014.total_votes)) as diff
 from e2019
 join e2014
 on e2019.pc_name = e2014.pc_name
 where e2019.party = 'INC'
 group by e2019.pc_name, e2019.party
 order by diff desc limit 5 );



-- Which constituencies have voted the most for NOTA
SELECT 
    (SELECT pc_name 
     FROM e2014 
     WHERE party = 'NOTA' 
     ORDER BY total_votes DESC 
     LIMIT 1) AS pc_name_2014,
    (SELECT MAX(total_votes) 
     FROM e2014 
     WHERE party = 'NOTA') AS max_total_votes_2014,
    (SELECT pc_name 
     FROM e2019 
     WHERE party = 'NOTA' 
     ORDER BY total_votes DESC 
     LIMIT 1) AS pc_name_2019,
    (SELECT MAX(total_votes) 
     FROM e2019 
     WHERE party = 'NOTA') AS max_total_votes_2019;



-- Which constituencies have elected candidates whose party has less than 10% vote share at state level in 2019
WITH RankedParties AS (
    SELECT 
        state, 
        pc_name, 
        party, 
        total_votes,
        ROW_NUMBER() OVER (PARTITION BY state, pc_name ORDER BY total_votes DESC) AS rn
    FROM e2019
)
SELECT *
FROM (
    SELECT *,
           (total_votes / SUM(total_votes) OVER (PARTITION BY state) * 100) AS per
    FROM RankedParties
    WHERE rn = 1
) AS subquery
WHERE per < 10;












