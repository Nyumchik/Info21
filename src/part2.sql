
CREATE OR REPLACE PROCEDURE add_p2p_check(checked_peer varchar, checking_peer varchar, 
                                task_name varchar, state check_status, this_time time) 
AS
$$
    DECLARE
        current_id bigint := 0;
        my_flag integer := -1;
    BEGIN
        IF (state = 'Start') THEN
            current_id = (SELECT max(id) FROM Checks) + 1;
            INSERT INTO Checks VALUES(current_id, checked_peer, task_name, now());
        ELSE
           IF EXISTS (SELECT check_id FROM P2P
					  JOIN Checks ON Checks.id = P2P.check_id
                    WHERE P2P.checking_peer_name = checking_peer
                    AND Checks.peer = checked_peer
                    AND Checks.task = task_name
                    AND P2P.state = 'Start'
					ORDER BY Checks.id DESC
					LIMIT 1) THEN
					
					current_id = (SELECT check_id FROM P2P
                    	JOIN Checks ON Checks.id = P2P.check_id
                    WHERE P2P.checking_peer_name = checking_peer
                    AND Checks.peer = checked_peer
                    AND Checks.task = task_name
                    AND P2P.state = 'Start'
					ORDER BY Checks.id DESC
					LIMIT 1); 
					my_flag = (SELECT count(check_id) FROM P2P WHERE check_id = current_id);
				ELSE
					RAISE NOTICE 'You must start checking';
                    my_flag = 0;
				END IF;
        END IF;
        IF my_flag >= 2 THEN
            RAISE NOTICE 'You must restart checking';
		ELSEIF my_flag = 0 THEN
			RAISE NOTICE 'You must start checking';
        ELSE 
        	INSERT INTO P2P VALUES ((SELECT max(id) FROM P2P) + 1, current_id, checking_peer, state, this_time);  
    	END IF;
	END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_verter_check(checked_peer varchar, task_name varchar, state check_status, this_time time) 
AS
$$
    DECLARE
        current_id bigint := 0;
        my_flag integer := -1;
    BEGIN

    IF EXISTS (SELECT Checks.id FROM P2P
                JOIN Checks ON Checks.id = P2P.check_id
            WHERE Checks.peer = checked_peer
            AND Checks.task = task_name
            AND P2P.state = 'Success' 
            ORDER BY Checks."date" DESC, P2P."time" DESC
            LIMIT 1 ) THEN

        current_id = (SELECT Checks.id FROM P2P
                JOIN Checks ON Checks.id = P2P.check_id
            WHERE Checks.peer = checked_peer
            AND Checks.task = task_name
            AND P2P.state = 'Success' 
            ORDER BY Checks."date" DESC, P2P."time" DESC
            LIMIT 1 );
    ELSE
        RAISE NOTICE 'You must start P2P check';
        my_flag = 1;
    END IF;
 
    IF state = 'Start' THEN
        RAISE NOTICE 'Verter knows when to start';
    ELSEIF my_flag = -1 THEN
        INSERT INTO Verter VALUES ((SELECT max(id) FROM Verter) + 1, current_id, 'Start', this_time);
        INSERT INTO Verter VALUES ((SELECT max(id) FROM Verter) + 1, current_id, state, this_time + interval '3 minute');
    END IF;
    END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION change_transferredPoints() RETURNS TRIGGER 
AS
$trg_transferredPoints$

    DECLARE
        checking_peer varchar;
        checked_peer  varchar;
    BEGIN
        IF (NEW.state = 'Start') THEN
            checking_peer = NEW.checking_peer_name;
            checked_peer = (SELECT peer FROM Checks
                            WHERE id = NEW.check_id);

        UPDATE TransferredPoints
        SET points_amount = points_amount + 1
        WHERE checking_peer_name = checking_peer
          AND checked_peer_name = checked_peer;
    END IF;
    RETURN NEW;
    END;
$trg_transferredPoints$ 
LANGUAGE plpgsql;

CREATE TRIGGER trg_transferredPoints
    AFTER INSERT ON P2P
    FOR EACH ROW
    EXECUTE FUNCTION change_transferredPoints();

CREATE OR REPLACE FUNCTION check_xp() RETURNS TRIGGER AS
$trg_check_xp$
    DECLARE
        max_xp integer = (SELECT maxXP FROM Tasks 
                        JOIN Checks ON tasks.title = Checks.task
                        WHERE Checks.id = NEW.check_id);
        p2p_st  check_status = (SELECT state FROM P2P
                        WHERE state != 'Start'
                        AND P2P.check_id = NEW.check_id);
        verter_st check_status = (SELECT state FROM Verter 
                        WHERE (state != 'Start' OR state IS NULL)
                        AND Verter.check_id = NEW.check_id);

    BEGIN
        IF (p2p_st = 'Success' AND verter_st = 'Failure') OR (p2p_st != 'Success') THEN
            RAISE NOTICE 'This project was fail';
            RETURN NULL;
        END IF;

        IF NEW.XP_amount <= max_xp THEN
            RETURN NEW;
        END IF;
        RETURN NULL;
    END;
$trg_check_xp$ 
LANGUAGE plpgsql;

CREATE TRIGGER trg_check_xp
    BEFORE INSERT ON XP
    FOR EACH ROW
    EXECUTE FUNCTION check_xp();

-- select * from p2p;

-- ---Tests for ex01----
--  CALL add_p2p_check('Goga', 'Lika', 'D1_Linux', 'Start', '10:00:00');  --good ex
--  CALL add_p2p_check('Goga', 'Lika', 'D1_Linux', 'Success', '10:30:00');

--  CALL add_p2p_check('Fedor', 'Goga', 'D1_Linux', 'Start', '10:00:00');  --good ex
--  CALL add_p2p_check('Fedor', 'Goga', 'D1_Linux', 'Failure', '10:30:00'); --good ex
--  CALL add_p2p_check('Fedor', 'Goga', 'D1_Linux', 'Success', '13:00:00'); -- bad ex

--  CALL add_p2p_check('Fedor', 'Goga', 'D1_Linux', 'Start', '14:00:00');  --good ex
--  CALL add_p2p_check('Fedor', 'Goga', 'D1_Linux', 'Success', '14:30:00'); --good ex

--  CALL add_p2p_check('Fedor', 'Lika', 'D1_Linux', 'Success', '13:00:00'); --bad ex


-- ----Tests for ex02----
-- CALL add_verter_check('Goga', 'D1_Linux', 'Success', '10:31:00'); --good ex
-- CALL add_verter_check('Fedor', 'D1_Linux', 'Failure', '14:31:00'); --good ex
-- CALL add_verter_check('Fedor', 'D1_Linux', 'Start', '14:31:00'); --bad ex

-- -----Test for ex03-----
-- SELECT * FROM transferredpoints;

-- -----Test for ex04-----
-- INSERT INTO XP VALUES (11, 13, 300); --good ex
-- INSERT INTO XP VALUES(12, 15, 300); -- fail ex
-- INSERT INTO XP VALUES(13, 2, 305); -- more xp

-- select * from xp;
