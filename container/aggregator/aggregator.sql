CREATE TABLE IF NOT EXISTS day (day date);

INSERT INTO day
SELECT i::date FROM GENERATE_SERIES((SELECT COALESCE(MAX(day), '2013-12-31')FROM day) + 1,
                                    CURRENT_DATE,
                                    '1 day'::interval) i;

CREATE INDEX IF NOT EXISTS date_idx ON event_log(date);

DROP MATERIALIZED VIEW IF EXISTS event_log_window_90 CASCADE;
CREATE MATERIALIZED VIEW event_log_window_90 AS (
    SELECT * FROM 
        event_log JOIN day ON 
            day BETWEEN 
                ((SELECT MAX(date) FROM event_log) - interval '180 day') 
                AND (SELECT MAX(date) FROM event_log)
            AND event_log.date BETWEEN (day - interval '90 day' ) AND day 
        
);

CREATE INDEX date_window_90_idx ON event_log_window_90(date);
