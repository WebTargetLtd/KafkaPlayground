CREATE OR REPLACE FUNCTION bips.ft_rawbips(IN _qty BIGINT)
RETURNS TABLE (LIKE bips.t_raw) 
AS $BODY$
DECLARE 
	_maxID bigint;
BEGIN
	/**
	 * --------------------------------------------------------------------------------------------
	 * @function        bips.ft_rawbips
	 * @scope           bips
	 * @description     Fetch the next batch of Bips to push to Kafka
	 * @usage           SELECT * FROM bips.ft_rawbips(12);
	 * @returns         _qty of bip.t_raw records
	 * @author          Neil Smith <Neil.Smith@WebTarget.co.uk>
	 * --------------------------------------------------------------------------------------------
	 * Whom?        	When?           Why?
	 * NRSmith			Sun 24 Mar 2024	Created
	 * ===========================================================================================
	*/
	CREATE TEMP TABLE IF NOT EXISTS t_matchedbips(LIKE bips.t_raw);

	INSERT INTO t_matchedbips
	SELECT 	r.* 
	FROM bips.t_raw r ,
		LATERAL (select counter_type, counter_value from bips.t_progress WHERE counter_type = 't_raw') p
		WHERE r.rawdata_id > p.counter_value
		ORDER BY r.rawdata_id
		LIMIT _qty;
	
	RETURN QUERY SELECT * from t_matchedbips;

	UPDATE bips.t_progress
	SET counter_value = (select max(rawdata_id) from t_matchedbips)
	WHERE counter_type = 't_raw';

	DROP TABLE t_matchedbips;

END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;

CREATE OR REPLACE FUNCTION bips.f_bipgun()
RETURNS BIGINT
AS $BODY$
DECLARE 
	_currentBipID bigint;
	_lastBipID bigint;
	_bipQty bigint = 1;
	_bipSleep bigint = 1;
	_totalQty bigint = 0;
	_ts timestamp with time zone;
BEGIN
	
	/**
	 * --------------------------------------------------------------------------------------------
	 * @function        bips.f_bipgun
	 * @scope           bips
	 * @description     Randomly copy bips from t_raw to t_bips, pausing as we go.
	 * @usage           SELECT * FROM bips.f_bipgun();
	 * @returns         _qty of bips fired.
	 * @author          Neil Smith <Neil.Smith@WebTarget.co.uk>
	 * --------------------------------------------------------------------------------------------
	 * Whom?        	When?           Why?
	 * NRSmith			Sun 24 Mar 2024	Created
	 * ===========================================================================================
	*/
	_lastBipID = MAX(rawdata_id) from bips.t_raw;
	_currentBipID = counter_value from bips.t_progress WHERE counter_type = 't_raw';
	RAISE NOTICE 'Current Bip ID %', _currentBipID;
	RAISE NOTICE 'Last Bip ID %', _lastBipID;

	WHILE _currentBipID < _lastBipID LOOP
		_ts=clock_timestamp();
		_bipQty=FLOOR(random() * 20 + 1)::int;
		_bipSleep=FLOOR(random() * 9 + 1)::int;
			
	    INSERT INTO bips.t_bips(bipuuid, userid, version, tsms, bip, bipuser)
	    SELECT 	(rawdata_src ->> 'uuid')::uuid as bipuuid,
	            (rawdata_src ->> 'userid')::bigint as userid,
	            (rawdata_src ->> 'version')::int as version,
	            (rawdata_src ->> 'timestamp_ms')::bigint as tsms,
	            rawdata_src ->> 'bip' as bip,
	            rawdata_src ->> 'user' as bipuser
	    FROM bips.ft_rawbips(_bipQty);

		_totalQty=_totalQty + _bipQty;
		_currentBipID = counter_value from bips.t_progress WHERE counter_type = 't_raw';

		RAISE NOTICE '[%] -- Total Records Processed :: [%] -- Fetching Records :: [%] -- Sleeping seconds :: [%] -- Last Bip Processed :: [%]', 
				_ts, _totalQty, _bipQty, _bipSleep, _currentBipID;

		-- PERFORM pg_sleep(_bipSleep);
		
	END LOOP;

	RETURN _totalQty;

END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 100;

-- SELECT * FROM bips.f_bipgun();
