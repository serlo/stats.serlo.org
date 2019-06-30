/* Create a day table for day aggregation. */

CREATE TABLE IF NOT EXISTS day (day date);
INSERT INTO day
SELECT i::date FROM GENERATE_SERIES((SELECT COALESCE(MAX(day), '2013-12-31')FROM day) + 1,
                                    CURRENT_DATE,
                                    '1 day'::interval) i;

/* Some metrics are expensive to aggregate daily, use weekly aggregation instead.*/
CREATE TABLE IF NOT EXISTS week (week date);
INSERT INTO week
SELECT i::date FROM GENERATE_SERIES((SELECT COALESCE(MAX(week), '2013-12-31')FROM week) + 1,
                                    CURRENT_DATE,
                                    '1 week'::interval) i;

CREATE INDEX IF NOT EXISTS date_idx ON event_log(date);

CREATE TABLE IF NOT EXISTS cache_active_authors(
    time date,
    authors int4,
    active_authors int4,
    very_active_authors int4
);

INSERT INTO cache_active_authors (
    SELECT 
        day as "time",
        count(author) as "authors",
        count(author_active) as "active authors",
        count(author_very_active) as "very active authors"
    FROM (
        SELECT day, actor_id,
            actor_id as author,
            CASE WHEN count(actor_id) > 10 THEN actor_id END as author_active,
            CASE WHEN count(actor_id) > 100 THEN actor_id END as author_very_active
        FROM event_log JOIN day ON 
            date BETWEEN day - interval '90 day' and day
            AND event_id IN (4,5)
            AND day >= '2018-01-01' 
            AND day <= (SELECT MAX(date) FROM event_log)
            AND day > (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_active_authors)
        GROUP BY day, actor_id
    ) activity 
    GROUP BY day 
    ORDER BY day ASC
);

CREATE TABLE IF NOT EXISTS cache_review_time(
    time date,
    perc_50 interval,
    perc_75 interval,
    perc_95 interval
);
INSERT INTO cache_review_time (
    SELECT
        day as time,
		percentile_cont(.5) WITHIN GROUP (ORDER BY el2.date - el1.date ASC) as perc_50,
		percentile_cont(.75) WITHIN GROUP (ORDER BY el2.date - el1.date ASC) as perc_75,
		percentile_cont(.95) WITHIN GROUP (ORDER BY el2.date - el1.date ASC) as perc_95
    FROM event_log el1
    INNER JOIN event_log el2 ON el1.uuid_id = el2.uuid_id 
        AND el1.date < el2.date
    INNER JOIN event e1 ON e1.id = el1.event_id
    INNER JOIN event e2 ON e2.id = el2.event_id
    JOIN day ON el1.date between day - interval '90 day' and day
    WHERE e1.name = 'entity/revision/add'
        AND e2.name = 'entity/revision/checkout'
        AND el1.actor_id != el2.actor_id
        AND el2.date - el1.date > interval '00:00:10'
        AND day <= (SELECT MAX(date) FROM event_log)
        AND day > (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_review_time)
    GROUP BY day
);
