
#include "data_collection.h"
#define SINK_ROLE 1
#define SENSOR_ROLE 2

#define COLLECT_TIMEOUT 60000
#define READ_TIMEOUT 5000

module DataCollectionC {

    uses {
            interface Boot;
            interface AMPacket;
            interface Packet as RadioPacket;
            interface PacketAcknowledgements;
            interface AMSend as RadioAMSend; 
            interface SplitControl as RadioControl;
            interface Receive;
            
            interface SplitControl as SerialControl;
    	    interface AMSend as SerialAMSend;
    	    interface Packet as SerialPacket; 
            
            interface Timer<TMilli> as CollectTimer;
            interface Timer<TMilli> as ReadTimer;
            interface Timer<TMilli> as RespTimer;
            interface Timer<TMilli> as RelayCollectTimer;
            interface Timer<TMilli> as RelayResponseTimer;
            
            interface Read<uint16_t> as TempRead;
            interface Read<uint16_t> as HumRead;
            
            interface Random;
        }
} implementation {

    uint16_t num_nodes = 10;
    
    const uint16_t RELAY_INTERVAL = 10000;
    const uint16_t RESP_INTERVAL = 10000;
    const uint16_t REL_COLLECT_INTERVAL = 200;
    
    //variabili
    uint8_t role = SENSOR_ROLE; // node ROLE
    
    uint16_t next_hop; //Next hop in the spanning tree in the route to the SINK
    uint8_t last_counter = 0; //Counter for collect message
    
    uint8_t i_t = 0, i_h = 0; //indexes for temp and hum
    
    uint16_t receive_counter = 0; //number of packets received by the SINK
    long last_msg_time = 0; // TODO save time of last receive (in the SINK)
    
    uint16_t avg_temp;
    uint16_t avg_hum;
    
    bool radio_busy = FALSE;
    
    message_t packet;
    message_t serialPacket;
    Message* receivedPayload;
    
    #define BUFFER_SIZE 20
    
    uint16_t relayTemp[BUFFER_SIZE], relayHum[BUFFER_SIZE], relayTempIndex = 0, relayHumIndex = 0;
    
    task void send_resp();
    task void relayCollect();
    task void relayResponse();
    
    

    //***************** Boot interface ********************//
    event void Boot.booted() {
        if(TOS_NODE_ID == 1){
            role = SINK_ROLE;
        }
        
        dbg("boot","Application booted.\n");
        dbg("boot","[role] My role is %u.\n",role);  
        
        call RadioControl.start(); //startup radio 
        call SerialControl.start();

    }
    
    //***************** RadioControl interface ********************//
    event void RadioControl.startDone(error_t err){
      
        if(err == SUCCESS) {

                dbg("radio","Radio on!\n");
                
                if(role == SINK_ROLE){
                
                    dbg("radio","[SINK] starting COLLECT timer.\n");
                    call CollectTimer.startPeriodic(COLLECT_TIMEOUT);
                }
                else {
                    call ReadTimer.startPeriodic(READ_TIMEOUT);
                }
        }
        else {
	        call RadioControl.start();
        }

    }   
  
    event void RadioControl.stopDone(error_t err){}
    
    //***************** SerialControl interface ********************//
    event void SerialControl.startDone(error_t err) {}
    
    event void SerialControl.stopDone(error_t err){}
    
    //********************* SerialAMSend interface ****************//
    event void SerialAMSend.sendDone(message_t* bufPtr, error_t error) {
        if (&serialPacket == bufPtr) {
            dbg("radio_send", "Serial Packet sent. STATUS = %d\n\n",error);
        } 
    }
    
    
    //***************** ReadTimer interface ********************//
    event void ReadTimer.fired() {
    
        call TempRead.read();
        call HumRead.read();
    
    }
    
    //***************** RespTimer interface ********************//
    event void RespTimer.fired() {
        post send_resp();
    }
    
    //***************** RelayCollectTimer interface ********************//
    event void RelayCollectTimer.fired() {
        post relayCollect();
    }
    
    //***************** RelayResponseTimer interface ********************//
    event void RelayResponseTimer.fired() {
        post relayResponse();
    }
    
    //***************** CollectTimer interface ********************//
    event void CollectTimer.fired() {
           
        Message* mess=(Message*)(call RadioPacket.getPayload(&packet,sizeof(Message)));
        
        if(last_counter > 0){
            dbg("sink", "[SINK] Packets received after last COLLECT: %hhu \n", receive_counter);
            
            dbg_clear("sink", "\t\tReceived packets: %.2lf% \n", ((double)(receive_counter*100.0/(num_nodes-1))) );
            dbg_clear("sink", "\t\tAverage temp: %u \n", avg_temp);
            dbg_clear("sink", "\t\tAverage humidity: %u \n", avg_hum);
            dbg_clear("csv", "%.2lf%,%u,%u\n",((double)(receive_counter*100.0/(num_nodes-1))), avg_temp, avg_hum);
        }
        
        last_counter++;
        receive_counter = 0;
        mess->msg_type = COLLECT;
        mess->counter = last_counter;
        mess->temp = 99;
        mess->hum = 99;
        
        if(call RadioAMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(Message)) == SUCCESS){
            
            dbg("radio_send", "COLLECT Packet passed to lower layer successfully! %s \n", sim_time_string());
            dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
            dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( &packet ) );
        
        }
    }
    
    //********************* RadioAMSend interface ****************//
    event void RadioAMSend.sendDone(message_t* buf,error_t err) {
    
        if(&packet == buf && err == SUCCESS ) {
	        dbg("radio_send", "Packet sent...");
	        radio_busy = FALSE;
	 
	        dbg_clear("radio_send", " at time %s \n", sim_time_string());
        } else {
                dbg("radio_error", "ERROR SENDING MESSAGE\n");
        }
    }
    
    //***************************** Receive interface *****************//
    event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

        Message* mess=(Message*)payload;
        receivedPayload = mess;
	    
	    dbg("radio_rec","Message received at time %s \n", sim_time_string());
	    dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	    dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	    dbg_clear("radio_pack","\t\t Payload \n" );
	    dbg_clear("radio_pack", "\t\t msg_type: %hhu \n", mess->msg_type);
	    
	    //depending on the message type choose what to do
	    switch(mess->msg_type){
	    
	        case COLLECT:
	            
	            // check if this is a new COLLECT request
	            if(mess->counter > last_counter){
	                
	                last_counter = mess->counter;
	                next_hop = call AMPacket.source( buf ); //set next-hop as the source of the packet
	                
	                dbg("next_hop", "I am node %hhu, my next hop is %hhu.\n", TOS_NODE_ID, next_hop);
	                
                        post relayCollect(); // relay COLLECT to nearby nodes
                   
                        call RespTimer.startOneShot( ( (call Random.rand16()) % RESP_INTERVAL) + 1500 );
                 
                }
	            break;
	            
	        case COLLECT_RESP:
	            
	            if(role == SINK_ROLE){
	                
	                dbg("sink", "[SINK] Received values {temp: %u, hum: %u} at %s \n", mess->temp, mess->hum, sim_time_string());
	                
	                if(receive_counter == 0){
	                    avg_temp = mess->temp;
	                    avg_hum = mess->hum;
	                } else {
	                    avg_temp = (avg_temp * receive_counter + mess->temp) / (receive_counter+1);
	                    avg_hum = (avg_hum * receive_counter + mess->hum) / (receive_counter+1);
	                }
	                receive_counter++;
	                               
	            } else {
	                
	                //keep last received value in buffer, limited to 10 elements.
	                if(relayTempIndex < BUFFER_SIZE && relayHumIndex < BUFFER_SIZE){
	                        relayTemp[relayTempIndex++] = mess->temp;
	                        relayHum[relayHumIndex++] = mess->hum;
	                        
	                        // relay message to next_hop
	                        call RelayResponseTimer.startOneShot((call Random.rand16()) % RELAY_INTERVAL);
                        }
                        
    
	            }
	            break;
	            
	    }
	    
	    return buf;
	    
	    
    }
    
    //************************* Read interface **********************//
    event void TempRead.readDone(error_t result, uint16_t data) {
        
        if(result == SUCCESS){
        
            if(i_t == 0){
                avg_temp = data;
                i_t++;
            } else {
            
            avg_temp = (avg_temp * i_t + data) / (i_t+1);
            i_t++;
            
            }
        }
    }

    event void HumRead.readDone(error_t result, uint16_t data) {
    
        if(result == SUCCESS){
            if(i_h == 0){
                avg_hum = data;
                i_h++;
            } else {
            
            avg_hum = (avg_hum * i_h + data) / (i_h+1);
            i_h++;
            
            }
        }
    }
    
    // Send a response to the next hop in the spanning tree. if radio busy try to resend.
    task void send_resp(){
       
        if(!radio_busy){
            Message* resp = (Message*)(call RadioPacket.getPayload(&packet,sizeof(Message)));
            dbg("radio_send", "SEND RESPONSE\n");
            resp->msg_type = COLLECT_RESP;
            resp->counter = last_counter;
            resp->temp = avg_temp;
            resp->hum = avg_hum;
            
            i_t = 0;
            i_h = 0;
            avg_temp = 0;
            avg_hum = 0;
            
            
            if(call RadioAMSend.send(next_hop,&packet,sizeof(Message)) == SUCCESS){
                
                radio_busy = TRUE;
                dbg("radio_send", "RESP Packet passed to lower layer successfully!\n");
                dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
                dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
                dbg_clear("radio_pack","\t Msg Type: %hhu \n ", resp->msg_type );
                dbg_clear("radio_pack","\t Temperature: %hhu \n ", resp->temp);
                dbg_clear("radio_pack","\t Humidity: %hhu \n", resp->hum );
            } else {
                dbg("radio_error", "ERROR SENDING RESPONSE\n");
            }
        } else { // radio is busy
            dbg("radio_error", "Tried sending RESP, but radio is busy.\n");
            call RespTimer.startOneShot((call Random.rand16()) % RESP_INTERVAL);
        }
    }
    
    task void relayCollect(){
        
        if(!radio_busy){
            Message* msg = (Message*)(call RadioPacket.getPayload(&packet,sizeof(Message)));
            dbg("radio_send", "RELAY COLLECT\n");
                    
            msg->msg_type = COLLECT;
            msg->counter = last_counter;


            if(call RadioAMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(Message)) == SUCCESS){
                
                radio_busy = TRUE;
                
                dbg("radio_send", "RELAY Packet passed to lower layer successfully!\n");
                dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
                dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
                dbg_clear("radio_pack","\t msg_type: %hhu \n ", msg->msg_type );
                dbg_clear("radio_pack","\t Counter: %hhu \n", msg->counter);
            } else {
                dbg("radio_error", "ERROR BROADCASTING COLLECT\n");
            }
        } else { // radio is busy
            dbg("radio_error", "Tried relaying COLLECT, but radio is busy.\n");
            call RelayCollectTimer.startOneShot((call Random.rand16()) % REL_COLLECT_INTERVAL);
        }
    }
    
    task void relayResponse() {
        
        if(!radio_busy){
                
                Message* msg = (Message*)(call RadioPacket.getPayload(&packet,sizeof(Message)));
                msg->msg_type = COLLECT_RESP;
                msg->counter = last_counter;
                msg->temp = relayTemp[--relayTempIndex];
                msg->hum = relayHum[--relayHumIndex];
                
                if(call RadioAMSend.send(next_hop,&packet,sizeof(Message)) == SUCCESS){
               
                    
                        dbg("relay_resp", "RELAY RESPONSE TO NEXT_HOP \n");
                        dbg_clear("relay_resp","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
                        dbg_clear("relay_resp","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
                        dbg_clear("relay_resp","\t msg_type: %hhu \n ", msg->msg_type );
                        dbg_clear("relay_resp","\t Counter: %hhu \n", msg->counter);
                        dbg_clear("relay_resp","\t temperature: %hhu \n", msg->temp);
                        dbg_clear("relay_resp","\t humidity: %hhu \n", msg->hum);
                        radio_busy = TRUE;
                } else {
                        dbg("radio_error", "ERROR RELAYING RESPONSE TO NEXT_HOP\n");
                }           
        } else { // radio is busy
            dbg("radio_error", "Tried relaying RESP, but radio is busy.\n");
            call RelayResponseTimer.startOneShot((call Random.rand16()) % RELAY_INTERVAL);
        }
        
    }
    
}

