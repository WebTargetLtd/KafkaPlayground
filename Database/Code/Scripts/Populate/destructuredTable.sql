
CREATE TABLE IF NOT EXISTS bips.t_bips 
(
    bip_id bigserial NOT NULL,
    bipuuid uuid,
    userid bigint, 
    version integer, 
    tsms bigint, 
    bip text COLLATE pg_catalog."default", 
    bipuser text COLLATE pg_catalog."default", 
    CONSTRAINT pk_bips 
    PRIMARY KEY (bip_id) 
) 
TABLESPACE pg_default;

ALTER TABLE bips.t_bips REPLICA IDENTITY FULL;
-- Table: bips.t_progress

-- DROP TABLE IF EXISTS bips.t_progress;

CREATE TABLE IF NOT EXISTS bips.t_progress
(
    counter_type character varying COLLATE pg_catalog."default" NOT NULL,
    counter_value bigint,
    CONSTRAINT t_progress_pkey PRIMARY KEY (counter_type)
) TABLESPACE pg_default;

INSERT INTO bips.t_progress(counter_type, counter_value) VALUES ('t_raw', 0);