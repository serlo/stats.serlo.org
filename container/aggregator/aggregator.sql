
/* Start a transaction */
BEGIN;

/* Create a version table for handling program updates */
CREATE TABLE IF NOT EXISTS version (version text PRIMARY KEY);
/* Add a default minimum version */
INSERT INTO version (version) SELECT '1.6.1' WHERE NOT EXISTS (SELECT * FROM version);
/* Next version */
CREATE OR REPLACE FUNCTION public.next_version() RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE AS 'SELECT ''1.7.0''::text';

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

/* Entities come in hierarchies, find all ancestors of an entity. */
/* TODO if community dashboard is too slow, materialize */
CREATE OR REPLACE VIEW entity_ancestor AS
WITH recursive ea AS (
    SELECT repository_id AS entity_id, entity_link.parent_id AS ancestor_id
    FROM entity_revision
    LEFT JOIN entity_link ON entity_link.child_id = repository_id
    UNION
    SELECT entity_id, el.parent_id
    FROM entity_link el
    INNER JOIN ea ON ea.ancestor_id = el.child_id)
SELECT * FROM ea;

CREATE TABLE IF NOT EXISTS cache_active_authors(
    time date UNIQUE,
    authors int4,
    active_authors int4,
    very_active_authors int4,
    active_teachers int4
);

INSERT INTO cache_active_authors (
    SELECT
        day as "time",
        count(author) as "authors",
        count(author_active) as "active authors",
        count(author_very_active) as "very active authors",
        count(author_active_teacher) as "active teachers"
    FROM (
        SELECT day, actor_id,
            actor_id as author,
            CASE WHEN count(actor_id) > 10 THEN actor_id END as author_active,
            CASE WHEN count(actor_id) > 100 THEN actor_id END as author_very_active,
            CASE WHEN count(actor_id) > 10 AND value IS NOT NULL THEN actor_id END as author_active_teacher
        FROM event_log JOIN day ON
            date BETWEEN day - interval '90 day' and day
            AND event_id = 5
            AND day >= '2018-01-01'
            AND day <= (SELECT MAX(date) FROM event_log)
            AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_active_authors)
            LEFT OUTER JOIN user_field ON
            user_id = actor_id
            AND field = 'interests'
            AND value = 'teacher'
        GROUP BY day, actor_id, value
    ) activity
    GROUP BY day
    ORDER BY day ASC
) ON CONFLICT (time) DO UPDATE SET
    authors = excluded.authors,
    active_authors = excluded.active_authors,
    very_active_authors = excluded.very_active_authors,
    active_teachers = excluded.active_teachers;

CREATE TABLE IF NOT EXISTS cache_active_reviewers(
    time date UNIQUE,
    reviewers int4,
    active_reviewers int4,
    very_active_reviewers int4
);

INSERT INTO cache_active_reviewers (
    SELECT
        day as "time",
        count(reviewer) as "reviewers",
        count(reviewer_active) as "active reviewers",
        count(reviewer_very_active) as "very active reviewers"
    FROM (
        SELECT day, el_review.actor_id,
            el_review.actor_id as reviewer,
            CASE WHEN count(el_review.actor_id) > 10 THEN el_review.actor_id END as reviewer_active,
            CASE WHEN count(el_review.actor_id) > 100 THEN el_review.actor_id END as reviewer_very_active
        FROM event_log AS el_review
    JOIN day ON
            date BETWEEN day - interval '90 day' and day
            AND (el_review.event_id = 6 or el_review.event_id = 11)
            AND day >= '2018-01-01'
            AND day <= (SELECT MAX(date) FROM event_log)
            AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_active_reviewers)
    INNER JOIN event_log AS el_revision ON
            el_review.uuid_id = el_revision.uuid_id
            AND el_review.date >= el_revision.date
            AND el_revision.event_id = 5
            AND el_revision.actor_id != el_review.actor_id
        GROUP BY day, el_review.actor_id
    ) activity
    GROUP BY day
    ORDER BY day ASC
) ON CONFLICT (time) DO UPDATE SET
    reviewers = excluded.reviewers,
    active_reviewers = excluded.active_reviewers,
    very_active_reviewers = excluded.very_active_reviewers;

CREATE TABLE IF NOT EXISTS cache_review_time90(
    time date UNIQUE,
    perc_50 interval,
    perc_75 interval,
    perc_95 interval
);

CREATE TABLE IF NOT EXISTS cache_review_time7(
    time date UNIQUE,
    perc_50 interval,
    perc_75 interval,
    perc_95 interval
);

CREATE TABLE IF NOT EXISTS cache_review_time1(
    time date UNIQUE,
    perc_50 interval,
    perc_75 interval,
    perc_95 interval
);

/* TODO: Fix incremental calculation (test with smoketest/aggregation.sh) */
DELETE FROM cache_review_time90 WHERE true;
DELETE FROM cache_review_time7 WHERE true;
DELETE FROM cache_review_time1 WHERE true;

INSERT INTO cache_review_time90 (
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
        AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_review_time90)
    GROUP BY day
) ON CONFLICT (time) DO UPDATE SET
    perc_50 = excluded.perc_50,
    perc_75 = excluded.perc_75,
    perc_95 = excluded.perc_95;

INSERT INTO cache_review_time7 (
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
    JOIN day ON el1.date between day - interval '7 day' and day
    WHERE e1.name = 'entity/revision/add'
        AND e2.name = 'entity/revision/checkout'
        AND el1.actor_id != el2.actor_id
        AND el2.date - el1.date > interval '00:00:10'
        AND day <= (SELECT MAX(date) FROM event_log)
        AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_review_time7)
    GROUP BY day
) ON CONFLICT (time) DO UPDATE SET
    perc_50 = excluded.perc_50,
    perc_75 = excluded.perc_75,
    perc_95 = excluded.perc_95;

INSERT INTO cache_review_time1 (
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
    JOIN day ON el1.date between day - interval '1 day' and day
    WHERE e1.name = 'entity/revision/add'
        AND e2.name = 'entity/revision/checkout'
        AND el1.actor_id != el2.actor_id
        AND el2.date - el1.date > interval '00:00:10'
        AND day <= (SELECT MAX(date) FROM event_log)
        AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_review_time1)
    GROUP BY day
) ON CONFLICT (time) DO UPDATE SET
    perc_50 = excluded.perc_50,
    perc_75 = excluded.perc_75,
    perc_95 = excluded.perc_95;

CREATE TABLE IF NOT EXISTS cache_edits_by_category(
    time date,
    category text,
    author_count int4,
    UNIQUE (time, category)
);

INSERT INTO cache_edits_by_category (
    SELECT
        day as time,
        category,
        count(actor) as author_count
    FROM (
        SELECT
            day,
            metadata.value as category,
            actor_id as actor,
            count(actor_id) as edits
        FROM event_log JOIN day ON
            event_id = 5
            AND date BETWEEN day - interval '90 day' AND day
            AND day <= (SELECT MAX(date) FROM event_log)
            AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_edits_by_category)
        JOIN entity_revision ON
            entity_revision.id = event_log.uuid_id
        JOIN metadata ON
            entity_revision.repository_id = metadata.uuid_id
            AND metadata.key_id = 1
        GROUP BY actor_id, day, metadata.value
        HAVING count(actor_id) > 0
    ) as authors
    GROUP BY day, category
) ON CONFLICT (time, category) DO UPDATE SET
    author_count = excluded.author_count;

CREATE TABLE IF NOT EXISTS cache_author_edits_by_category (
    time date,
    author bigint,
    category text,
    edit_count int4,
    UNIQUE (time, author, category)
);

DO $$
BEGIN
    IF (SELECT * FROM version) < (SELECT public.next_version()) THEN
        DELETE FROM cache_author_edits_by_category;
    END IF;
END $$;

INSERT INTO cache_author_edits_by_category (
    SELECT
        date_trunc('day', event_log.date) as time,
        actor_id as author,
        metadata.value as category,
        count(event_id) as edit_count
    FROM event_log
    JOIN entity_revision ON
        entity_revision.id = event_log.uuid_id
    LEFT JOIN entity_link ON
        entity_link.child_id = entity_revision.repository_id
    JOIN entity_ancestor ON
        entity_ancestor.entity_id = entity_revision.repository_id
    JOIN metadata ON
        (metadata.uuid_id = entity_ancestor.entity_id AND entity_ancestor.ancestor_id IS NULL OR metadata.uuid_id = entity_ancestor.ancestor_id)
        AND metadata.key_id = 1
    WHERE
        event_id = 5
    GROUP BY 1, actor_id, metadata.value
    HAVING count(actor_id) > 0
) ON CONFLICT (time, author, category) DO UPDATE SET
    edit_count = excluded.edit_count;
/* TODO check this ON CONFLICT, it's always true */

CREATE TABLE IF NOT EXISTS cache_author_reviews (
    time date,
    author bigint,
    review_count int4,
    UNIQUE (time, author)
);

INSERT INTO cache_author_reviews (
    SELECT
        day as time,
        actor_id as author,
        count(event_id) as review_count
    FROM event_log JOIN day ON
        (event_id = 6 OR event_id = 11)
        AND date BETWEEN day - interval '90 day' AND day
        AND day <= (SELECT MAX(date) FROM event_log)
        AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_author_reviews)
    JOIN entity_revision ON
        entity_revision.id = event_log.uuid_id
    GROUP BY day, actor_id
    HAVING count(actor_id) > 0
) ON CONFLICT (time, author) DO UPDATE SET
    review_count = excluded.review_count;

CREATE TABLE IF NOT EXISTS cache_mfnf_author_edits_by_category (
    time date,
    topic text,
    authors int4,
    active_authors int4,
    very_active_authors int4,
    UNIQUE (time, topic)
);

INSERT INTO cache_mfnf_author_edits_by_category (
    SELECT
        day as "time",
        topic,
        count(author) as authors,
        count(author_active) as active_authors,
        count(author_very_active) as very_active_authors
    FROM (
        SELECT day, name, topic,
            name as author,
            CASE WHEN sum(number_of_edits) >= 10 THEN name END as author_active,
            CASE WHEN sum(number_of_edits) >= 100 THEN name END as author_very_active
        FROM mfnf_edits JOIN day ON
            date BETWEEN day - interval '90 day' and day
            AND day >= '2018-01-01'
            AND day <= (SELECT MAX(date) FROM mfnf_edits)
            AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_mfnf_author_edits_by_category)
        GROUP BY day, name, topic
    ) activity
    GROUP BY day, topic
    ORDER BY day ASC
) ON CONFLICT (time, topic) DO UPDATE SET
    authors = excluded.authors,
    active_authors = excluded.active_authors,
    very_active_authors = excluded.very_active_authors;

CREATE TABLE IF NOT EXISTS cache_mfnf_author_edits (
    time date UNIQUE,
    authors int4,
    active_authors int4,
    very_active_authors int4
);

INSERT INTO cache_mfnf_author_edits (
    SELECT
        day as "time",
        count(author) as authors,
        count(author_active) as active_authors,
        count(author_very_active) as very_active_authors
    FROM (
        SELECT day, name,
            name as author,
            CASE WHEN sum(number_of_edits) >= 10 THEN name END as author_active,
            CASE WHEN sum(number_of_edits) >= 100 THEN name END as author_very_active
        FROM mfnf_edits JOIN day ON
            date BETWEEN day - interval '90 day' and day
            AND day >= '2018-01-01'
            AND day <= (SELECT MAX(date) FROM mfnf_edits)
            AND day >= (SELECT COALESCE(MAX(time), '2013-12-31') FROM cache_mfnf_author_edits)
        GROUP BY day, name
    ) activity
    GROUP BY day
    ORDER BY day ASC
) ON CONFLICT (time) DO UPDATE SET
    authors = excluded.authors,
    active_authors = excluded.active_authors,
    very_active_authors = excluded.very_active_authors;

/* Update the version and clean up */
UPDATE version SET version = (SELECT public.next_version());
DROP FUNCTION public.next_version();

/* commit the aggregation transaction */
COMMIT;


/* create serlo user in minikube to avoid errors with permission granting */
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT                       -- SELECT list can stay empty for this
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'serlo_readonly') THEN
      CREATE USER serlo_readonly NOCREATEDB;
   END IF;
END
$do$;

GRANT CONNECT ON DATABASE kpi TO serlo_readonly;
GRANT USAGE ON SCHEMA public TO serlo_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO serlo_readonly;

