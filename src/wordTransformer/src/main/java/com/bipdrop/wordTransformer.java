package com.bipdrop;

import java.util.*;

import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.Topology;
import org.apache.kafka.streams.kstream.Branched;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.common.serialization.StringDeserializer;

public class wordTransformer {

    private final static String TOPIC = System.getenv("BIPTOPIC");
    private final static String FILTERGROUP_ID = System.getenv("FILTERGROUPID");
    private final static String GROUP_ID = System.getenv("GROUPID");
    private final static String TOPICFILTH = System.getenv("FILTHTOPIC");
    private final static String TOPICCLEAN = System.getenv("CLEANTOPIC");
    private final static String BOOTSTRAP_SERVERS = new StringBuilder().append(System.getenv("BOOTSTRAPSERVERS")).append(":")
    .append(System.getenv("KAFKAPORT")).toString();

    // Define the list of values to check for a match
    private final static List<String> matchList = Arrays.asList("fun", "happy", "joy", "laugh");
    
    public static void main(String[] args) {
        
        System.out.printf("BIP TOPIC : %s\n", TOPIC);
        System.out.printf("CLEAN TOPIC : %s\n", TOPICCLEAN);
        System.out.printf("FILTH TOPIC : %s\n", TOPICFILTH);
        System.out.printf("BOOTSTRAP : %s\n", BOOTSTRAP_SERVERS);
        System.out.printf("FILTERGROUP_ID : %s\n", FILTERGROUP_ID);

        // Set up properties for the Consumer
        Properties props = new Properties();

        props.put(StreamsConfig.APPLICATION_ID_CONFIG, FILTERGROUP_ID);
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(StreamsConfig.CACHE_MAX_BYTES_BUFFERING_DOC, "0");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, GROUP_ID);
        props.put(ConsumerConfig.ALLOW_AUTO_CREATE_TOPICS_CONFIG, "true");

        try {

            StreamsBuilder streamsBuilder = new StreamsBuilder();
            System.out.println("Creating Streams");
            
            Topology topology = makeStream(streamsBuilder);
            System.out.println(topology.describe());
            
            KafkaStreams streams = new KafkaStreams(topology, props);
            System.out.println("Starting Streams");
            streams.start();
            
            System.out.println("Adding shutdown hook");
            Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

        } catch (Exception e) {
            System.out.printf("Exception caught :: %s", e);
        }

    }

    public static Topology makeStream(StreamsBuilder streamsBuilder) {

        KStream<String, String> kStream = streamsBuilder.stream(TOPIC);
            
        kStream.split()
        .branch((key, value) -> matchList.stream().anyMatch(value::contains),
                Branched.withConsumer((ks) -> ks.to(TOPICFILTH)))
        .defaultBranch(Branched.withConsumer((ks) -> ks.to(TOPICCLEAN)));
        return streamsBuilder.build();
   
    }
}
