# Kafka Playground

A project to quickly and easy create a local Kafka environment, with example datasets, filters and consumers and CDC detection.

The code has been developed on Linux. It may work on other platforms, but is untried. It has been tried on a Raspberry Pi 5 and Ubuntu 22.04.

It streams data from PostgreSQL in a Kafka Topic, as well as search for banned words and splitting resultant set into TOPIC_FILTH and TOPIC_CLEAN. The banned words are:

    - happy
    - laugh
    - joy
    - fun 

If an incoming record contains one of these words, it will be put in the the TOPIC_FILTH topic, otherwise it will go into TOPIC_CLEAN.

## Getting started.

Make sure you have docker and docker-compose installed and clone the repo.

The data file used is too big for GitHub, so is hosted separately. Download the file `landingBips.sql.gz`: from https://nc.webtarget.co.uk/s/7wcsjYjKSEtriGR to `Database\Code\Scripts\Populate`

### Building the JARs

Assuming you have JDK 11 installed, building the JARs is as simple as running a BASH script. Because, in fact, it is, just running a BASH script.

Pre-Built JARs can be found at https://nc.webtarget.co.uk/s/7wcsjYjKSEtriGR and should be copied into `Docker\consumer` (KafkaConsumer-1.0-SNAPSHOT-jar-with-dependencies) and `Docker\filthfilter` (wordTransformer-1.0-SNAPSHOT-jar-with-dependencies)

#### Building the Consumer

To create the single .JAR file for the Consumer container to run:

```sh
    cd src/KafkaConsumer
    ./buildConsumer..sh
```

This will create the file and copy it to the correct folder for the Dockerfile to ingest.

#### Building the filter

```sh
    cd src/wordTransformer
    ./buildWordTransformer.sh

```
This will create the file and copy it to the correct folder for the Dockerfile to ingest.

## Post Dependencies

Once the dependecies have been met, the container stack can be built:

```sh

    cd Docker
    docker-compose up

```

The command will load, install and configure containers for 

    - Kafka
    - Zookeeper
    - Debezium
    - PostgreSQL
    - Schema Registry
    - Kafka-UI (https://github.com/provectus/kafka-ui)
    - An example consumer
    - An example data stream topic filter and splitter

## The data.

A new PostgreSQL 16 database (kafkasrc_db) will be created on first boot and loaded with over 5 million JSON records. These records are adapted from a public tweet archive.

Once the data has loaded, PostgreSQL will autovacuum the table.

Open a browser to [http://<hostname>:8082](http://hostname:8082). You should be able to see 3 Kafka Topics; `bips.bips.t_bips`, `TOPIC_CLEAN` and `TOPIC_FILTH`. 

## CDC

Debezium uses PostgreSQL's logical replication to hook into the database's log to pull changes into Kafka. To enable the Debezium CDC mechanism, we have to provide a JSON configuration file:

```sh

    cd Database\Code\Scripts\Debezium
    curl -i -X POST 127.0.0.1:8083/connectors/ -H "Accept:application/json" -H "Content-Type:application/json" --data "@debezium.json"

```

You can check that the Bip-Connector loaded properly. It should be returned in the output from :

```sh

    curl http://127.0.0.1:8083/connectors

```

Pausing, resuming and deleting the connector is also possible:

```sh

    curl -X PUT http://127.0.0.1:8083/connectors/bip-connector/pause

    curl -X PUT http://127.0.0.1:8083/connectors/bip-connector/resume

    curl -i -X DELETE http://127.0.0.1:8083/connectors/bip-connector

```

## Loading Kafka

The Debezium connector will stream data into Kafka when data is Inserted, Deleted or Updated in the `bips.t_bips` table.

When the connections have been made, run some destructured data into the watched table. This can be done with manual SQL or dripped out from a shell script.

### Shell Script "Drip Feed"

```sh
    docker exec -it kafkadb_src bash
    cd Scripts/loadBips
    ./loadBips.sh

```

### Manual Bulk Insert

This one is more exciting. We have over 5 million records to transfer. We can do big batches with this. Just change the quantity in the `FROM` line.

```sql

    -- Insert 100,000 records into the t_bips and Kafka
	INSERT INTO bips.t_bips(bipuuid, userid, version, tsms, bip, bipuser)
	SELECT 	(rawdata_src ->> 'uuid')::uuid as bipuuid,
			(rawdata_src ->> 'userid')::bigint as userid,
			(rawdata_src ->> 'version')::int as version,
			(rawdata_src ->> 'timestamp_ms')::bigint as tsms,
			rawdata_src ->> 'bip' as bip,
			rawdata_src ->> 'user' as bipuser
	FROM bips.ft_rawbips(100000);

```

Once the data is loaded into the t_bips table and the db transcation has committed (about 3 seconds for 10K records on the RPI5), then Debezium will pick the records from the log and they'll start to appear in the kafka-ui.

## Speed

### Rpi5

Kafka ingests at around 58,712 per minute. Extrapolating this: 1 million should take 1,000,000 / 55,000 = 18.18mins

### Ryzen 3, 16GB

Kafka ingested at around 277,910 per minute. Extrapolating this: 1 million should take 3.6mins for 1,000,000 records
