#!/bin/bash
# set -e

#
# --------------------------------------------------------------------------------------------------------------
# @file         loadBips.sh
# @arguments    
#
# @description  Runs import numerous times
# @output
# @author       NRSmith <Neil.Smith@WebTarget.co.uk>
# @CalledFrom	CLI
# --------------------------------------------------------------------------------------------------------------
# Whom?         When?            Why?
# NRSmith       Sun 24 Mar 2024  Creation
# ==============================================================================================================
#

_psql="psql postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE} "

getCount() {
    echo `${_psql} -qtAX -c "select count(*) from $1;" `
}

getRemainder() {
    echo `getCount "bips.t_raw r WHERE r.rawdata_id > (SELECT counter_value FROM bips.t_progress WHERE counter_type='t_raw')"`
}

performImport() {
    echo `${_psql} -qtAX -c "SELECT * FROM bips.f_bipgun();"`
}

commitTransaction() {
    echo `${_psql} -qtAX -c "commit;"`
}
loopLoad() {

    remainder=`getRemainder`
    while [ $remainder -gt 0 ]
    do
        performImport
        commitTransaction
        remainder=`getRemainder`
    done

}
loopLoad