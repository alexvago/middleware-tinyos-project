
#include "data_collection.h"

configuration DataCollectionAppC {}

implementation {

        components MainC, DataCollectionC as App, RandomC;
        
        
        App.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
        
        //radio components
        components new AMSenderC(AM_MY_MSG);
        components new AMReceiverC(AM_MY_MSG);
        components ActiveMessageC;
        
        //Serial components
        components SerialActiveMessageC as Serial;
        
        //Send and Receive interfaces
        App.Receive -> AMReceiverC;
        App.RadioAMSend -> AMSenderC;

        //Radio Control
        App.RadioControl -> ActiveMessageC;
        
        //Serial Control
        App.SerialControl -> Serial;
        App.SerialAMSend -> Serial.AMSend[AM_TEST_SERIAL_MSG];
        App.SerialPacket -> Serial;
        
        //Interfaces to access package fields
        App.AMPacket -> AMSenderC;
        App.RadioPacket -> AMSenderC;
        App.PacketAcknowledgements->ActiveMessageC;
        
        //timers
        components new TimerMilliC() as CollectTimer;
        components new TimerMilliC() as ReadTimer;
        components new TimerMilliC() as RespTimer;
        components new TimerMilliC() as RelayCollectTimer;
        components new TimerMilliC() as RelayResponseTimer;

        //sensors
        components new TempHumSensorC();
        
        //Boot interface
        App.Boot -> MainC.Boot;
        
        //Timer interfaces
        App.CollectTimer -> CollectTimer;
        App.ReadTimer -> ReadTimer;
        App.RespTimer -> RespTimer;
        App.RelayCollectTimer -> RelayCollectTimer;
        App.RelayResponseTimer -> RelayResponseTimer;
        //Temp sensor Read
        App.TempRead -> TempHumSensorC.TempRead;
        App.HumRead -> TempHumSensorC.HumRead;


}
