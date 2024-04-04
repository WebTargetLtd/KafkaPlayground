-- Table: bips.t_rawdata

-- DROP TABLE IF EXISTS bips.t_raw;

CREATE TABLE IF NOT EXISTS bips.t_raw
(
    rawdata_id bigint NOT NULL ,
    rawdata_src jsonb NOT NULL,
    rawdata_uuid uuid,
    isdisabled timestamp without time zone,
    isdeleted timestamp without time zone,
    life_id bigint,
    create_user bigint,
    update_user bigint,
    rec_attrib jsonb,
    rec_sortorder bigint DEFAULT 0,
    rec_updated timestamp without time zone DEFAULT now(),
    rec_created timestamp without time zone,
    rec_search tsvector,
    CONSTRAINT bips_t_raw_pk PRIMARY KEY (rawdata_id)
    
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS bips.t_raw
    OWNER to postgres;
