DROP TABLE IF EXISTS Peers CASCADE;
DROP TABLE IF EXISTS Tasks CASCADE;
DROP TYPE IF EXISTS check_status CASCADE;
DROP TABLE IF EXISTS Checks CASCADE;
DROP TABLE IF EXISTS P2P CASCADE;
DROP TABLE IF EXISTS Verter CASCADE;
DROP TABLE IF EXISTS TransferredPoints CASCADE;
DROP TABLE IF EXISTS Friends CASCADE;
DROP TABLE IF EXISTS Recommendations CASCADE;
DROP TABLE IF EXISTS XP CASCADE;
DROP TABLE IF EXISTS TimeTracking CASCADE;
DROP PROCEDURE IF EXISTS export(tablename TEXT, path TEXT, delimiter CHAR) CASCADE;
DROP PROCEDURE IF EXISTS import(tablename TEXT, path TEXT, delimiter CHAR) CASCADE;

CREATE TABLE Peers (
    nickname varchar primary key NOT NULL,
    birthday date NOT NULL
);

INSERT INTO Peers VALUES ('Ilia', '1990-01-01');
INSERT INTO Peers VALUES ('Lila', '2000-08-08');
INSERT INTO Peers VALUES ('Goga', '1997-02-03');
INSERT INTO Peers VALUES ('Fedor', '2002-05-29');
INSERT INTO Peers VALUES ('Lika', '1995-07-16');

CREATE TABLE Tasks (
    title varchar primary key NOT NULL,
    parent_task varchar REFERENCES Tasks(title) DEFAULT NULL,
    maxXP bigint NOT NULL
);

INSERT INTO Tasks VALUES ('D1_Linux', NULL, 300);
INSERT INTO Tasks VALUES ('D2_Linux_Network', 'D1_Linux', 350);
INSERT INTO Tasks VALUES ('D3_Linux_Monitoring_v1.0', 'D2_Linux_Network', 350);
INSERT INTO Tasks VALUES ('D4_Linux_Monitoring_v2.0', 'D3_Linux_Monitoring_v1.0', 501);
INSERT INTO Tasks VALUES ('D5_SimpleDocker', 'D3_Linux_Monitoring_v1.0', 300);
INSERT INTO Tasks VALUES ('D6_CICD', 'D5_SimpleDocker', 300);

CREATE TYPE check_status AS ENUM 
(
    'Start', 
    'Success', 
    'Failure'
);

CREATE TABLE Checks (
    id bigint primary key NOT NULL,
    peer varchar NOT NULL REFERENCES Peers(nickname),
    task varchar NOT NULL REFERENCES Tasks(title),
    "date" date NOT NULL
);

INSERT INTO Checks VALUES (1, 'Ilia', 'D1_Linux', '2023-06-20');
INSERT INTO Checks VALUES (2, 'Lila', 'D5_SimpleDocker', '2023-06-20');
INSERT INTO Checks VALUES (3, 'Goga', 'D4_Linux_Monitoring_v2.0', '2023-06-20');
INSERT INTO Checks VALUES (4, 'Ilia', 'D2_Linux_Network', '2023-06-21');
INSERT INTO Checks VALUES (5, 'Lila', 'D6_CICD', '2023-06-21');
INSERT INTO Checks VALUES (6, 'Goga', 'D4_Linux_Monitoring_v2.0', '2023-06-22');
INSERT INTO Checks VALUES (7, 'Fedor', 'D1_Linux', '2023-06-23');
INSERT INTO Checks VALUES (8, 'Fedor', 'D2_Linux_Network', '2023-06-24');
INSERT INTO Checks VALUES (9, 'Ilia', 'D3_Linux_Monitoring_v1.0', '2023-06-24');
INSERT INTO Checks VALUES (10, 'Ilia', 'D4_Linux_Monitoring_v2.0', '2023-06-25');
INSERT INTO Checks VALUES (11, 'Lika', 'D4_Linux_Monitoring_v2.0', '2023-06-25');
INSERT INTO Checks VALUES (12, 'Lika', 'D4_Linux_Monitoring_v2.0', '2023-06-28');


CREATE TABLE P2P (
    id bigint primary key NOT NULL,
    check_id bigint NOT NULL REFERENCES Checks(id),
    checking_peer_name varchar NOT NULL REFERENCES Peers(nickname),
    state check_status NOT NULL,
    "time" time without time zone
);

INSERT INTO P2P VALUES (1, 1, 'Lika', 'Start', '10:00:00');
INSERT INTO P2P VALUES (2, 1, 'Lika', 'Success', '10:30:00');
INSERT INTO P2P VALUES (3, 2, 'Ilia', 'Start', '10:00:00');
INSERT INTO P2P VALUES (4, 2, 'Ilia', 'Success', '10:30:00');
INSERT INTO P2P VALUES (5, 3, 'Lila', 'Start', '12:30:00');
INSERT INTO P2P VALUES (6, 3, 'Lila', 'Failure', '13:00:00');
INSERT INTO P2P VALUES (7, 4, 'Goga', 'Start', '10:30:00');
INSERT INTO P2P VALUES (8, 4, 'Goga', 'Success', '11:00:00');
INSERT INTO P2P VALUES (9, 5, 'Ilia', 'Start', '13:00:00');
INSERT INTO P2P VALUES (10, 5, 'Ilia', 'Success', '13:30:00');
INSERT INTO P2P VALUES (11, 6, 'Lila', 'Start', '13:00:00');
INSERT INTO P2P VALUES (12, 6, 'Lila', 'Success', '13:30:00');
INSERT INTO P2P VALUES (13, 7, 'Goga', 'Start', '10:00:00');
INSERT INTO P2P VALUES (14, 7, 'Goga', 'Success', '10:30:00');
INSERT INTO P2P VALUES (15, 8, 'Lila', 'Start', '11:00:00');
INSERT INTO P2P VALUES (16, 8, 'Lila', 'Success', '11:30:00');
INSERT INTO P2P VALUES (17, 9, 'Fedor', 'Start', '17:00:00');
INSERT INTO P2P VALUES (18, 9, 'Fedor', 'Success', '17:30:00');
INSERT INTO P2P VALUES (19, 10, 'Lika', 'Start', '17:00:00');
INSERT INTO P2P VALUES (20, 10, 'Lika', 'Success', '17:30:00');
INSERT INTO P2P VALUES (21, 11, 'Ilia', 'Start', '17:00:00');
INSERT INTO P2P VALUES (22, 11, 'Ilia', 'Failure', '17:30:00');
INSERT INTO P2P VALUES (23, 12, 'Lila', 'Start', '17:00:00');
INSERT INTO P2P VALUES (24, 12, 'Lila', 'Success', '17:30:00');


CREATE TABLE Verter (
    id bigint primary key NOT NULL,
    check_id bigint NOT NULL REFERENCES Checks(id),
    state check_status NOT NULL,
    "time" time NOT NULL
);

INSERT INTO Verter VALUES (1, 1, 'Start',  '10:35:00');
INSERT INTO Verter VALUES (2, 1, 'Success', '10:38:00');
INSERT INTO Verter VALUES (3, 2, 'Start', '10:35:00');
INSERT INTO Verter VALUES (4, 2, 'Success', '10:38:00');
INSERT INTO Verter VALUES (5, 4, 'Start', '11:01:00');
INSERT INTO Verter VALUES (6, 4, 'Success', '11:05:00');
INSERT INTO Verter VALUES (7, 5, 'Start', '13:31:00');
INSERT INTO Verter VALUES (8, 5, 'Success', '13:35:00');
INSERT INTO Verter VALUES (9, 6, 'Start', '13:31:00');
INSERT INTO Verter VALUES (10, 6, 'Failure', '13:34:00');
INSERT INTO Verter VALUES (11, 7, 'Start', '10:31:00');
INSERT INTO Verter VALUES (12, 7, 'Success', '10:35:00');
INSERT INTO Verter VALUES (13, 8, 'Start',  '11:31:00');
INSERT INTO Verter VALUES (14, 8, 'Failure', '11:35:00');
INSERT INTO Verter VALUES (15, 9, 'Start', '17:31:00');
INSERT INTO Verter VALUES (16, 9, 'Success', '17:35:00');
INSERT INTO Verter VALUES (17, 10, 'Start', '17:31:00');
INSERT INTO Verter VALUES (18, 10, 'Success', '17:35:00');
INSERT INTO Verter VALUES (19, 12, 'Start', '17:31:00');
INSERT INTO Verter VALUES (20, 12, 'Failure', '17:35:00');

CREATE TABLE TransferredPoints (
    id bigint primary key NOT NULL,
    checking_peer_name varchar NOT NULL REFERENCES Peers(nickname),
    checked_peer_name varchar NOT NULL REFERENCES Peers(nickname),
    points_amount bigint NOT NULL
);

INSERT INTO TransferredPoints VALUES (1, 'Ilia', 'Lika', 1);
INSERT INTO TransferredPoints VALUES (2, 'Lika', 'Ilia', 2);
INSERT INTO TransferredPoints VALUES (3, 'Ilia', 'Goga', 0);
INSERT INTO TransferredPoints VALUES (4, 'Goga', 'Ilia', 1);
INSERT INTO TransferredPoints VALUES (5, 'Ilia', 'Fedor', 0);
INSERT INTO TransferredPoints VALUES (6, 'Fedor', 'Ilia', 1);
INSERT INTO TransferredPoints VALUES (7, 'Ilia', 'Lila', 2);
INSERT INTO TransferredPoints VALUES (8, 'Lila', 'Ilia', 0);
INSERT INTO TransferredPoints VALUES (9, 'Lila', 'Goga', 2);
INSERT INTO TransferredPoints VALUES (10, 'Goga', 'Lila', 0);
INSERT INTO TransferredPoints VALUES (11, 'Lila', 'Fedor', 1);
INSERT INTO TransferredPoints VALUES (12, 'Fedor', 'Lila', 0);
INSERT INTO TransferredPoints VALUES (13, 'Lila', 'Lika', 1);
INSERT INTO TransferredPoints VALUES (14, 'Lika', 'Lila', 0);
INSERT INTO TransferredPoints VALUES (15, 'Goga', 'Fedor', 1);
INSERT INTO TransferredPoints VALUES (16, 'Fedor', 'Goga', 0);
INSERT INTO TransferredPoints VALUES (17, 'Goga', 'Lika', 0);
INSERT INTO TransferredPoints VALUES (18, 'Lika', 'Goga', 0);
INSERT INTO TransferredPoints VALUES (19, 'Fedor', 'Lika', 0);
INSERT INTO TransferredPoints VALUES (20, 'Lika', 'Fedor', 0);

CREATE TABLE Friends (
    id bigint primary key NOT NULL,
    peer1_name varchar NOT NULL REFERENCES Peers(nickname),
    peer2_name varchar NOT NULL REFERENCES Peers(nickname)
);

INSERT INTO Friends VALUES (1, 'Ilia', 'Lila');
INSERT INTO Friends VALUES (2, 'Lila', 'Goga');
INSERT INTO Friends VALUES (3, 'Ilia', 'Lika');
INSERT INTO Friends VALUES (4, 'Lika', 'Lila');
INSERT INTO Friends VALUES (5, 'Goga', 'Fedor');

CREATE TABLE Recommendations (
    id bigint primary key NOT NULL,
    peer varchar NOT NULL REFERENCES Peers (nickname),
    recommended_peer varchar NOT NULL REFERENCES Peers (nickname)
);

INSERT INTO Recommendations VALUES (1, 'Ilia', 'Lila');
INSERT INTO Recommendations VALUES (2, 'Lila', 'Goga');
INSERT INTO Recommendations VALUES (3, 'Ilia', 'Lika');
INSERT INTO Recommendations VALUES (4, 'Lika', 'Lila');
INSERT INTO Recommendations VALUES (5, 'Goga', 'Fedor');

CREATE TABLE XP (
    id bigint primary key NOT NULL,
    check_id bigint NOT NULL  REFERENCES Checks (id),
    XP_amount bigint NOT NULL
);

INSERT INTO XP VALUES (1, 1, 300);
INSERT INTO XP VALUES (2, 2, 300);
INSERT INTO XP VALUES (3, 3, 501);
INSERT INTO XP VALUES (5, 5, 300);
INSERT INTO XP VALUES (6, 6, 501);
INSERT INTO XP VALUES (7, 7, 300);
INSERT INTO XP VALUES (9, 9, 350);
INSERT INTO XP VALUES (10, 10, 501);

CREATE TABLE TimeTracking (
    id bigint primary key NOT NULL,
    peer varchar NOT NULL REFERENCES Peers (nickname),
    "date" date NOT NULL,
    "time" time NOT NULL,
    state bigint NOT NULL CHECK (state IN (1, 2))
);

INSERT INTO TimeTracking VALUES (1, 'Ilia', '2023-06-20', '09:00:00', 1);
INSERT INTO TimeTracking VALUES (2, 'Ilia', '2023-06-20', '15:00:00', 2);
INSERT INTO TimeTracking VALUES (3, 'Lila', '2023-06-20', '09:35:00', 1);
INSERT INTO TimeTracking VALUES (4, 'Lila', '2023-06-20', '12:00:00', 2);
INSERT INTO TimeTracking VALUES (5, 'Goga', '2023-06-20', '12:00:00', 1);
INSERT INTO TimeTracking VALUES (6, 'Goga', '2023-06-20', '13:00:00', 2);
INSERT INTO TimeTracking VALUES (7, 'Ilia', '2023-06-21', '09:00:00', 1);
INSERT INTO TimeTracking VALUES (8, 'Ilia', '2023-06-21', '19:00:00', 2);
INSERT INTO TimeTracking VALUES (9, 'Lila', '2023-06-21', '11:00:00', 1);
INSERT INTO TimeTracking VALUES (10, 'Lila', '2023-06-21', '15:00:00', 2);
INSERT INTO TimeTracking VALUES (11, 'Goga', '2023-06-22', '07:00:00', 1);
INSERT INTO TimeTracking VALUES (12, 'Goga', '2023-06-22', '17:00:00', 2);
INSERT INTO TimeTracking VALUES (13, 'Fedor', '2023-06-23', '08:00:00', 1);
INSERT INTO TimeTracking VALUES (14, 'Fedor', '2023-06-23', '17:00:00', 2);
INSERT INTO TimeTracking VALUES (15, 'Fedor', '2023-06-24', '08:00:00', 1);
INSERT INTO TimeTracking VALUES (16, 'Fedor', '2023-06-24', '17:00:00', 2);
INSERT INTO TimeTracking VALUES (17, 'Ilia', '2023-06-24', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (18, 'Ilia', '2023-06-24', '20:00:00', 2);
INSERT INTO TimeTracking VALUES (19, 'Ilia', '2023-06-25', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (20, 'Ilia', '2023-06-25', '20:00:00', 2);
INSERT INTO TimeTracking VALUES (21, 'Lika', '2023-06-25', '15:00:00', 1);
INSERT INTO TimeTracking VALUES (22, 'Lika', '2023-06-25', '20:00:00', 2);
INSERT INTO TimeTracking VALUES (23, 'Lika', '2023-06-28', '16:00:00', 1);
INSERT INTO TimeTracking VALUES (24, 'Lika', '2023-06-28', '22:00:00', 2);

CREATE PROCEDURE export(tablename TEXT, path TEXT, delimiter CHAR) 
AS 
$$
    BEGIN
        EXECUTE 
        format('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;',
        tablename, path, delimiter);
    END;
$$ 
LANGUAGE plpgsql;

CREATE PROCEDURE import(tablename TEXT, path TEXT, delimiter CHAR)
AS
$$
    BEGIN
        EXECUTE 
        format('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;',
        tablename, path, delimiter);
    END;
$$
LANGUAGE plpgsql;

-- CALL export('Peers', '/private/tmp/Peers.csv', ',');
-- SELECT * FROM peers;
-- CALL import('Peers', '/private/tmp/PeersIN.csv', ',');
-- SELECT * FROM peers;
