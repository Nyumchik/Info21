DROP FUNCTION IF EXISTS fnc_points_amount();
DROP FUNCTION IF EXISTS fnc_xp();
DROP FUNCTION IF EXISTS fnc_peers_in_campus(check_day date);

DROP FUNCTION IF EXISTS fnc_points_change();
DROP FUNCTION IF EXISTS fnc_points_change_from_FPC();

--ex01
CREATE OR REPLACE FUNCTION fnc_points_amount()
RETURNS TABLE ("Peer1" varchar, "Peer2" varchar, "PointsAmount" bigint) 
AS 
$$
    BEGIN
        RETURN QUERY (
            SELECT tp1.checking_peer_name, tp1.checked_peer_name, (tp1.points_amount - tp2.points_amount)
            FROM TransferredPoints tp1
            JOIN TransferredPoints tp2 ON tp1.checking_peer_name = tp2.checked_peer_name 
            AND tp1.checked_peer_name = tp2.checking_peer_name 
            AND tp1.id < tp2.id
        );
    END;
$$ 
LANGUAGE plpgsql;

--SELECT * FROM fnc_points_amount();

--ex02

CREATE OR REPLACE FUNCTION fnc_xp()
RETURNS TABLE ("Peer" varchar, "Task" varchar, "XP" bigint) 
AS 
$$
    BEGIN
        RETURN QUERY (SELECT Checks.peer, Checks.task, XP.XP_Amount
                      FROM XP
                      JOIN Checks ON XP.check_id = Checks.id
                      JOIN P2P ON Checks.id = p2p.check_id
                      JOIN Verter ON Checks.id = Verter.check_id
                      WHERE P2P.state = 'Success' AND Verter.state = 'Success'
        );
    END;
$$ 
LANGUAGE plpgsql;

--SELECT * FROM fnc_xp();

--ex03

CREATE OR REPLACE FUNCTION fnc_peers_in_campus(check_day date)
RETURNS TABLE ("Peers" varchar) 
AS 
$$
    BEGIN
        RETURN QUERY (SELECT Peer
                      FROM TimeTracking
                      WHERE TimeTracking."date" = check_day
                      GROUP BY Peer
                      HAVING COUNT(State) < 3
        );
    END;
$$ 
LANGUAGE plpgsql;

INSERT INTO TimeTracking VALUES (25, 'Lika', '2023-06-29', '12:00:00', 1);
INSERT INTO TimeTracking VALUES (26, 'Lika', '2023-06-29', '13:00:00', 2);
INSERT INTO TimeTracking VALUES (27, 'Lika', '2023-06-29', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (28, 'Lika', '2023-06-29', '17:00:00', 2);
SELECT * FROM fnc_peers_in_campus('2023-06-29');
SELECT * FROM fnc_peers_in_campus('2023-06-20');

select * from TimeTracking;

--ex04
DROP PROCEDURE IF EXISTS prc_points_change(res REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_points_change(res REFCURSOR) 
AS 
$$
BEGIN
    OPEN res FOR
    SELECT "Peer", sum("PointsChange") AS "PointsChange"
        FROM (
            SELECT checking_peer_name AS "Peer", 
                    points_amount AS "PointsChange"
            FROM TransferredPoints

        UNION ALL

        SELECT checked_peer_name AS "Peer", 
                0 - points_amount AS "PointsChange" 
        FROM TransferredPoints) AS f 
        GROUP BY "Peer"
        ORDER BY "PointsChange" DESC;
END;
$$ 
LANGUAGE plpgsql;

BEGIN; 
CALL prc_points_change('res');
FETCH ALL FROM "res";
END;

--ex05

DROP PROCEDURE IF EXISTS prc_points_change_from_FPA(res REFCURSOR);

CREATE OR REPLACE PROCEDURE prc_points_change_from_FPA(ref REFCURSOR) 
AS
$$
    BEGIN
        OPEN ref FOR
        SELECT "Peer", sum("PointsChange") AS "PointsChange"
        FROM (SELECT "Peer1" AS "Peer", sum("PointsAmount") AS "PointsChange"
              FROM fnc_points_amount()
              GROUP BY "Peer1"

              UNION

              SELECT "Peer2" AS "Peer", -1 * sum("PointsAmount") AS "PointsChange"
              FROM fnc_points_amount()
              GROUP BY "Peer2"
              ORDER BY "PointsChange" DESC) AS t

        GROUP BY "Peer"
        ORDER BY "PointsChange" DESC;
    END;
$$ 
LANGUAGE plpgsql;

BEGIN;
CALL prc_points_change_from_FPA('ref');
FETCH ALL IN "ref";
END;

--ex06

DROP PROCEDURE IF EXISTS prc_popular_task(ref REFCURSOR);

CREATE OR REPLACE PROCEDURE prc_popular_task(ref REFCURSOR) 
AS
$$
    BEGIN
        OPEN ref FOR
        WITH t1 AS (SELECT Checks.task, Checks."date", count(*) AS counts
                                   FROM Checks
                                   GROUP BY Checks.task, Checks."date"),

             t2 AS (SELECT t1.task, t1."date", rank() OVER (PARTITION BY t1."date" ORDER BY counts DESC) AS rank
                        FROM t1)
        
        SELECT TO_CHAR("date", 'dd.mm.yyyy') AS "Day", t2.task AS "Task"
        FROM t2
        WHERE rank = 1
        ORDER BY "date" DESC;
    END;
$$ 
LANGUAGE plpgsql;

BEGIN;
CALL prc_popular_task('ref');
FETCH ALL IN "ref";
END;

--ex07
DROP PROCEDURE IF EXISTS pr_peers_completed_block(name varchar, curs1 refcursor);

CREATE OR REPLACE PROCEDURE pr_peers_completed_block(name varchar, curs1 refcursor) 
AS 
$$
    BEGIN
        OPEN curs1 FOR
        WITH t1 AS (SELECT *
                     FROM Tasks
                     WHERE title SIMILAR TO CONCAT(name, '[0-9]%')),
             check_task AS (SELECT MAX(title) AS title FROM t1),
             check_date AS (SELECT Checks.peer, Checks.task, Checks."date"
                            FROM Checks
                            JOIN P2P ON Checks.id = P2P.check_id AND P2P.State = 'Success'
                            JOIN Verter ON Checks.id = Verter.check_id AND Verter.State = 'Success')
        SELECT check_date.Peer AS "Peer", TO_CHAR("date", 'dd.mm.yyyy') AS "Day"
        FROM check_date
        JOIN check_task ON check_date.Task = check_task.title;
    END;
$$ 
LANGUAGE plpgsql;

BEGIN;
CALL pr_peers_completed_block('D', 'curs1');
FETCH ALL IN "curs1";
END;

--ex08
DROP PROCEDURE IF EXISTS prc_recommended_peer(ref REFCURSOR);

CREATE OR REPLACE PROCEDURE prc_recommended_peer(ref REFCURSOR)
AS 
$$
    BEGIN
        OPEN ref FOR 
        WITH t1 AS (SELECT Nickname,
            (CASE WHEN Nickname = Friends.peer1_name THEN peer2_name
                ELSE peer1_name END) AS t FROM Peers
                JOIN Friends ON Peers.Nickname = Friends.peer1_name OR peers.Nickname = Friends.peer2_name),
        t2 AS (SELECT t1.Nickname, Recommendations.recommended_peer, COUNT(Recommendations.recommended_peer) 
            AS count FROM t1
                JOIN Recommendations ON t1.t = Recommendations.Peer
            WHERE t1.Nickname != Recommendations.recommended_peer
            GROUP BY t1.Nickname, Recommendations.recommended_peer),
        t3 AS (SELECT Nickname
                FROM t2
                GROUP BY Nickname)
        SELECT t2.Nickname AS "Peer", t2.recommended_peer AS "RecommendedPeer"
        FROM t2
            JOIN t3 ON t2.Nickname = t3.Nickname
        WHERE t2.count = (SELECT MAX(count) FROM t2);
    END;
$$ 
LANGUAGE plpgsql;

BEGIN;
CALL prc_recommended_peer('ref');
FETCH ALL IN "ref";
END;


--ex09
DROP PROCEDURE IF EXISTS prc_started_blocks(block1 varchar, block2 varchar, ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_started_blocks(block1 varchar, block2 varchar, ref REFCURSOR)
AS
$$
DECLARE
    count_peers integer := (SELECT COUNT(peers.nickname)
                        FROM peers);
BEGIN
    OPEN ref FOR 
        WITH startedblock1 AS (SELECT DISTINCT peer FROM Checks
                               WHERE Checks.task SIMILAR TO concat(block1, '[0-9]_%')),
             startedblock2 AS (SELECT DISTINCT peer FROM Checks
                               WHERE Checks.task SIMILAR TO concat(block2, '[0-9]_%')),
             startedboth AS (SELECT DISTINCT startedblock1.peer FROM startedblock1
                                JOIN startedblock2 ON startedblock1.peer = startedblock2.peer),
             startedoneof AS (SELECT DISTINCT peer
                              FROM ((SELECT * FROM startedblock1) 
                              UNION 
                              (SELECT * FROM startedblock2)) AS a),

             count_startedblock1 AS (SELECT count(*) AS count_startedblock1 FROM startedblock1),
             count_startedblock2 AS (SELECT count(*) AS count_startedblock2 FROM startedblock2),
             count_startedboth AS (SELECT count(*) AS count_startedboth FROM startedboth),
             count_startedoneof AS (SELECT count(*) AS count_startedoneof FROM startedoneof)


        SELECT ((SELECT count_startedblock1::bigint FROM count_startedblock1) * 100 / count_peers) AS "StartedBlock1",
               ((SELECT count_startedblock2::bigint FROM count_startedblock2) * 100 / count_peers) AS "StartedBlock2",
               ((SELECT count_startedboth::bigint FROM count_startedboth) * 100 / count_peers) AS "StartedBothBlocks",
               ((SELECT count_peers - count_startedoneof::bigint FROM count_startedoneof) * 100 / count_peers) AS "DidntStartAnyBlock";

END;
$$
LANGUAGE plpgsql;

BEGIN;
CALL prc_started_blocks('C', 'CPP', 'ref');
FETCH ALL IN "ref";
END;

BEGIN;
CALL prc_started_blocks('D', 'SQL', 'ref');
FETCH ALL IN "ref";
END;

INSERT INTO Tasks VALUES ('SQL1_SQL_Bootcamp', 'D6_CICD', 1500);
INSERT INTO Checks VALUES (16, 'Lila', 'SQL1_SQL_Bootcamp', '2023-08-08');
INSERT INTO P2P VALUES (31, 16, 'Lila', 'Start', '17:00:00');
INSERT INTO P2P VALUES (32, 16, 'Lila', 'Success', '17:30:00');
INSERT INTO Verter VALUES (25, 16, 'Start', '17:31:00');
INSERT INTO Verter VALUES (26, 16, 'Success', '17:35:00');

BEGIN;
CALL prc_started_blocks('D', 'SQL', 'ref');
FETCH ALL IN "ref";
END;

--ex10
DROP PROCEDURE IF EXISTS prc_birthday(ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_birthday(ref REFCURSOR)
AS 
$$
    BEGIN
   OPEN ref FOR
	    WITH success AS (
            SELECT COUNT(*) AS amount FROM Peers 
                JOIN Checks ON (Checks.peer = Peers.nickname)
                LEFT JOIN Verter ON Verter.check_id = Checks.id
	            LEFT JOIN P2P ON P2P.check_id = Checks.id
	            WHERE ((Verter.state = 'Success' OR Verter.state IS NULL) 
                    AND P2P.state= 'Success' 
                    AND (EXTRACT(DAY FROM Peers.birthday) = EXTRACT(DAY FROM Checks."date")) 
                    AND (EXTRACT(MONTH FROM Peers.birthday) = EXTRACT(MONTH FROM Checks."date")))
            GROUP BY Peers.nickname),

        failure AS (
            SELECT COUNT(*) AS amount FROM Peers
                JOIN Checks ON (Checks.Peer = Peers.nickname)
                LEFT JOIN Verter ON Verter.check_id = Checks.id
	            LEFT JOIN P2P ON P2P.check_id = Checks.id
	        WHERE ((Verter.state = 'Failure' OR Verter.state IS NULL) 
                AND P2P.state = 'Failure' AND (EXTRACT(DAY FROM Peers.birthday) = EXTRACT(DAY FROM Checks."date")) 
                AND (EXTRACT(MONTH FROM Peers.birthday) = EXTRACT(MONTH FROM Checks."date")))
            GROUP BY Peers.nickname), 

        total_peers AS (
            SELECT COALESCE(ps.amount, 0) + COALESCE((SELECT ms.amount FROM failure AS ms), 0) AS amount
	        FROM success AS ps
)

SELECT (COALESCE((ps.amount::float), 0) / (SELECT amount FROM total_peers) * 100)::bigint AS "SuccessfulChecks", 
    (COALESCE((SELECT amount FROM failure)::float, 0) / (SELECT amount FROM total_peers) * 100)::bigint AS "UnsuccessfulChecks"
FROM success AS ps;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL prc_birthday('ref');
FETCH ALL IN "ref";
END;

--ex11
DROP PROCEDURE IF EXISTS prc_first_and_second_success_third_fail( task1 varchar, task2 varchar, task3 varchar, res REFCURSOR); 
CREATE OR REPLACE PROCEDURE prc_first_and_second_success_third_fail( task1 varchar, task2 varchar, task3 varchar, res REFCURSOR) 
AS 
$$
    BEGIN
        OPEN res FOR
        WITH t1 AS (SELECT peers.nickname FROM checks 
                    JOIN peers ON checks.peer = peers.nickname
                    JOIN p2p ON p2p.check_id = checks.id
		            FULL JOIN verter ON verter.check_id = checks.id
		        WHERE task = task1 AND p2p.state = 'Success' 
		        AND (verter.state = 'Success')
		    ),

	        t2 AS (SELECT peers.nickname FROM checks 
                    JOIN peers ON checks.peer = peers.nickname
                    JOIN p2p ON p2p.check_id = checks.id
		            FULL JOIN verter ON verter.check_id = checks.id
		        WHERE task = task2 AND p2p.state = 'Success' 
		        AND (verter.state = 'Success')
		    ),

	        t3 AS (SELECT peers.nickname FROM checks 
                    JOIN peers ON checks.peer = peers.nickname
                    JOIN p2p ON p2p.check_id = checks.id
		            FULL JOIN verter ON verter.check_id = checks.id
		        WHERE task = task3 AND (p2p.state = 'Success' OR p2p.state = 'Failure' OR p2p.state = NULL)
		        AND (verter.state = 'Success' OR Verter.state = 'Failure' OR verter.state = NULL)
		    ),

	        t12 AS (SELECT t1.nickname FROM t1		
			    JOIN t2 ON t1.nickname = t2.nickname )

            SELECT t12.nickname AS "Peers" FROM t12
                JOIN t3 ON t12.nickname != t3.nickname;
    END;
$$ 
LANGUAGE plpgsql;


-- BEGIN;
-- CALL prc_first_and_second_success_third_fail('D1_Linux', 'D2_Linux_Network', 'D6_CICD', 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_first_and_second_success_third_fail('D1_Linux', 'D2_Linux_Network', 'D3_Linux_Monitoring_v1.0', 'ref');
-- FETCH ALL IN "ref";
-- END;


--ex12
DROP PROCEDURE IF EXISTS prc_parent_task(ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_parent_task(ref REFCURSOR)
AS 
$$
    BEGIN
        OPEN ref FOR 
        WITH RECURSIVE r AS (SELECT (CASE WHEN Tasks.parent_task IS NULL THEN 0 ELSE 1 END) AS count, 
                                    Tasks.Title, Tasks.parent_task, Tasks.parent_task
                            FROM Tasks

                            UNION ALL

                            SELECT (CASE WHEN Tasks.parent_task IS NOT NULL THEN count + 1 ELSE count END) AS count,  
                                    Tasks.title, Tasks.parent_task, r.title
                            FROM Tasks
                                CROSS JOIN r
                                WHERE r.Title LIKE Tasks.parent_task)
                      SELECT Title AS "Task", 
                            max(count) AS "PrevCount"
                      FROM r
                      GROUP BY Title
                      ORDER BY max(count);
    END;
$$ 
LANGUAGE plpgsql;

BEGIN;
CALL prc_parent_task('ref');
FETCH ALL IN "ref";
END;


--ex13
DROP PROCEDURE IF EXISTS prc_lucky_day(count bigint, ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_lucky_day(count bigint, ref REFCURSOR) 
AS 
$$
    BEGIN
        OPEN ref FOR
            WITH t1 AS (SELECT * FROM Checks
                         JOIN P2P on Checks.Id = P2P.check_id
                         LEFT JOIN Verter ON Checks.id = Verter.check_id
                         JOIN Tasks ON Checks.Task = Tasks.Title
                         JOIN XP ON Checks.Id = XP.check_id
                         WHERE P2P.state = 'Success' AND (Verter.State = 'Success' OR Verter.state = NULL))
            
            SELECT "date" FROM t1
            WHERE t1.XP_amount >= t1.maxXP * 0.8
            GROUP BY "date"
            HAVING count("date") >= count;
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_lucky_day(1,'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_lucky_day(2,'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_lucky_day(3,'ref');
-- FETCH ALL IN "ref";
-- END;

--ex14
DROP PROCEDURE IF EXISTS prc_max_xp(ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_max_xp(ref REFCURSOR)
AS 
$$
    BEGIN
        OPEN ref FOR 
        SELECT Checks.peer AS "Peer", sum(XP_amount) AS "XP"
        FROM XP
            JOIN Checks ON XP.check_id = Checks.id
        GROUP BY "Peer"
        ORDER BY sum(XP_amount) DESC 
        LIMIT 1;
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_max_xp('ref');
-- FETCH ALL IN "ref";
-- END;

--ex15
DROP PROCEDURE IF EXISTS prc_came_earlier(arrival_time time, N integer, ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_came_earlier(arrival_time time, N integer, ref REFCURSOR) 
AS 
$$
    BEGIN
        OPEN ref FOR
            SELECT peer AS "Peer" FROM TimeTracking
            WHERE state = 1 AND "time" < arrival_time
            GROUP BY peer
            HAVING COUNT(peer) >= N;
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_came_earlier('12:00:00', 1, 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_came_earlier('12:00:00', 2, 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_came_earlier('12:00:00', 3, 'ref');
-- FETCH ALL IN "ref";
-- END;

--ex16
DROP PROCEDURE IF EXISTS prc_count_leaving_campus(N integer, M integer, ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_count_leaving_campus(N integer, M integer, ref REFCURSOR)
AS
$$
    BEGIN
        OPEN ref FOR
            SELECT peer AS "Peer"
            FROM (SELECT peer, "date", count(*) AS counts
                FROM TimeTracking
                WHERE state = 2 AND "date" > (current_date - N)
                GROUP BY peer, "date"
                ORDER BY "date") AS res
            GROUP BY peer
            HAVING sum(counts) > M;
    END;
$$ 
LANGUAGE plpgsql;

-- BEGIN;
-- CALL prc_count_leaving_campus(180, 1, 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_count_leaving_campus(180, 3, 'ref');
-- FETCH ALL IN "ref";
-- END;

-- BEGIN;
-- CALL prc_count_leaving_campus(180, 4, 'ref');
-- FETCH ALL IN "ref";
-- END;

--ex17
DROP PROCEDURE IF EXISTS prc_percent_of_entrances(ref REFCURSOR);
CREATE OR REPLACE PROCEDURE prc_percent_of_entrances(ref REFCURSOR)
AS 
$$
    BEGIN
        OPEN ref FOR
            WITH t AS (SELECT nickname, EXTRACT(month FROM birthday) AS birthday
                        FROM Peers),

                t1 AS (SELECT COUNT(*) AS count, birthday
                        FROM (SELECT Peer, "date", birthday
                                FROM TimeTracking
                                    JOIN t ON TimeTracking.Peer = t.Nickname
                                    WHERE State = 1 AND EXTRACT(month FROM "date") = birthday
                                    GROUP BY Peer, "date", birthday) AS f
                        GROUP BY birthday),

                t2 AS (SELECT COUNT(*) AS count1, birthday
                        FROM (SELECT peer, "date", birthday
                                FROM TimeTracking
                                    JOIN t ON TimeTracking.peer = t.nickname
                                    WHERE State = 1 AND EXTRACT(month FROM "date") = birthday AND "time" < '12:00:00'
                                    GROUP BY Peer, "date", birthday) AS f1
                        GROUP BY birthday)

                      SELECT (CASE WHEN t1.birthday = 1 THEN 'January'
                              WHEN t1.birthday = 2 THEN 'February'
                              WHEN t1.birthday = 3 THEN 'March'
                              WHEN t1.birthday = 4 THEN 'April'
                              WHEN t1.birthday = 5 THEN 'May'
                              WHEN t1.birthday = 6 THEN 'June'
                              WHEN t1.birthday = 7 THEN 'July'
                              WHEN t1.birthday = 8 THEN 'August'
                              WHEN t1.birthday = 9 THEN 'September'
                              WHEN t1.birthday = 10 THEN 'October'
                              WHEN t1.birthday = 11 THEN 'November'
                              WHEN t1.birthday = 12 THEN 'December'
                              ELSE 'Bad month'
                              END) AS "Month", 
                              ((t2.count1 * 100) / t1.count)::real AS "EarlyEntries"
                      FROM t1
                        JOIN t2 ON t1.birthday = t2.birthday
                      GROUP BY t1.birthday, t2.count1, t1.count;
    END;
$$ 
LANGUAGE plpgsql;

INSERT INTO TimeTracking VALUES (29, 'Lila', '2023-08-08', '11:00:00', 1);
INSERT INTO TimeTracking VALUES (30, 'Lila', '2023-08-08', '22:00:00', 2);
INSERT INTO TimeTracking VALUES (31, 'Lila', '2023-08-09', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (32, 'Lila', '2023-08-09', '17:00:00', 2);
INSERT INTO TimeTracking VALUES (33, 'Lila', '2023-08-10', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (34, 'Lila', '2023-08-10', '17:00:00', 2);

INSERT INTO TimeTracking VALUES (35, 'Lika', '2023-07-09', '11:00:00', 1);
INSERT INTO TimeTracking VALUES (36, 'Lika', '2023-07-09', '17:00:00', 2);

-- BEGIN;
-- CALL prc_percent_of_entrances('ref');
-- FETCH ALL IN "ref";
-- END;
