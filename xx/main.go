package main

import (
	"fmt"
	"gopkg.in/Shopify/sarama.v1"
	"log"
	"os"
	"strings"
	"sync"
)

func main(){
	Producer()
	//Consumer()
}

var (
	wg     sync.WaitGroup
	logger = log.New(os.Stderr, "[srama] ", log.LstdFlags)
)

func Consumer() {

	sarama.Logger = logger
	consumer, err := sarama.NewConsumer(strings.Split("172.30.11.101:9092,172.30.11.103:9092,172.30.11.106:9092", ","), nil)

	if err != nil {
		logger.Println("Failed to start consumer: %s", err)
	}

	partitionList, err := consumer.Partitions("hello")

	if err != nil {
		logger.Println("Failed to get the list of partitions: ", err)
	}

	for partition := range partitionList {

		pc, err := consumer.ConsumePartition("hello", int32(partition), sarama.OffsetNewest)

		if err != nil {
			logger.Printf("Failed to start consumer for partition %d: %s\n", partition, err)
		}
		defer pc.AsyncClose()

		wg.Add(1)
		go func(sarama.PartitionConsumer) {

			defer wg.Done()
			for msg := range pc.Messages() {
				fmt.Printf("Partition:%d, Offset:%d, Key:%s, Value:%s", msg.Partition, msg.Offset, string(msg.Key), string(msg.Value))
				fmt.Println()
			}
		}(pc)

	}

	wg.Wait()
	logger.Println("Done consuming topic hello")
	consumer.Close()

}

func Producer() {

	sarama.Logger = logger

	config := sarama.NewConfig()
	config.Producer.RequiredAcks = sarama.WaitForAll
	config.Producer.Partitioner = sarama.NewRandomPartitioner
	config.Producer.Return.Successes = true

	msg := &sarama.ProducerMessage{}

	msg.Topic = "hello"
	msg.Partition = int32(-1)
	msg.Key = sarama.StringEncoder("key")
	msg.Value = sarama.ByteEncoder("你好, 世界!")

	producer, err := sarama.NewSyncProducer(strings.Split("172.30.11.101:9092,172.30.11.103:9092,172.30.11.106:9092", ","), config)

	if err != nil {

		logger.Println("Failed to produce message: %s", err)
		os.Exit(500)
	}

	defer producer.Close()

	partition, offset, err := producer.SendMessage(msg)

	if err != nil {
		logger.Println("Failed to produce message: ", err)
	}

	logger.Printf("partition=%d, offset=%d\n", partition, offset)

}
