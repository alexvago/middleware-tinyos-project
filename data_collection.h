#ifndef DATA_COLLECTION_H
#define DATA_COLLECTION_H

#define COLLECT 1
#define COLLECT_RESP 2

typedef nx_struct Message {
	nx_uint8_t msg_type;
	nx_uint8_t counter;
	nx_uint16_t temp;
	nx_uint16_t hum;
} Message;


enum{
AM_MY_MSG = 6,
};

enum {
  AM_TEST_SERIAL_MSG = 0x89,
};

#endif
