import com.bipdrop.BipConsumer;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.junit.Rule;
import org.junit.contrib.java.lang.system.EnvironmentVariables;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;


public class BipConsumerTest {

    @Test
    public void test_continuous_polling() {
        Consumer<String, String> consumer = Mockito.mock(Consumer.class);
        BipConsumer.consumeTopic(consumer);
        Mockito.verify(consumer, Mockito.atLeastOnce()).poll(Duration.ofMillis(1000));
    }

    public static Properties getProperties() {
        Properties props = new Properties();
        props.setProperty("bootstrap.servers", "127.0.0.1:9092");
        props.setProperty("group.id", "1");
        props.setProperty("enable.auto.commit", "true");
        props.setProperty("auto.commit.interval.ms", "10000");
        props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

        // Set to earliest to read from the beginning of the topic
        props.put("auto.offset.reset", "earliest");
        return props;
    }
}