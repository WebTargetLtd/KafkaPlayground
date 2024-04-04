package com.bipdrop;


import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

public class BipConsumer {

    private static final Logger logger = LoggerFactory.getLogger(BipConsumer.class);

    public static final String TOPIC = System.getenv("BIPTOPIC");
    public static final String BOOTSTRAP_SERVERS = System.getenv("BOOTSTRAPSERVERS") + ":" +
            System.getenv("KAFKAPORT");
    public static final
    String GROUP_ID = System.getenv("GROUPID");

    public static void main(String[] args) throws Exception {

        logger.info("BIPTOPIC : {}", TOPIC);
        logger.info("BOOTSTRAP : {}", BOOTSTRAP_SERVERS);
        logger.info("GROUP_ID : {}", GROUP_ID);
        runner();

    }
    private static void runner() {
        Properties props = getProperties();
        Consumer<String, String> consumer = createConsumer(props);
        subscribeTopic(consumer);
        consumeTopic(consumer);
    }

    private static Consumer<String, String> createConsumer(Properties props) {
        return new org.apache.kafka.clients.consumer.KafkaConsumer<>(props);
    }
    private static void subscribeTopic(Consumer<String, String> consumer) {
        consumer.subscribe(Collections.singletonList(TOPIC));
    }

    public static void consumeTopic(Consumer<String, String> consumer) {
        {

            
                while (true) {
                    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));
                    consumer.commitAsync();
                }
            
        }
    }



    public static Properties getProperties() {
        Properties props = new Properties();
        props.setProperty("bootstrap.servers", BOOTSTRAP_SERVERS);
        props.setProperty("group.id", GROUP_ID);
        props.setProperty("enable.auto.commit", "true");
        props.setProperty("auto.commit.interval.ms", "10000");
        props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

        // Set to earliest to read from the beginning of the topic
        props.put("auto.offset.reset", "earliest");
        return props;
    }
}