
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
        
        //Send and Receive interfaces
        App.Receive -> AMReceiverC;
        App.RadioAMSend -> AMSenderC;

        //Radio Control
        App.RadioControl -> ActiveMessageC;
        
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
        
        components LocalTimeMilliC;
        
        //Timer interfaces
        App.CollectTimer -> CollectTimer;
        App.ReadTimer -> ReadTimer;
        App.RespTimer -> RespTimer;
        App.RelayCollectTimer -> RelayCollectTimer;
        App.RelayResponseTimer -> RelayResponseTimer;
        App.LocalTime -> LocalTimeMilliC;

        //sensors
        components new TempHumSensorC();
        
        //Boot interface
        App.Boot -> MainC.Boot;
        
        
        //Temp sensor Read
        App.TempRead -> TempHumSensorC.TempRead;
        App.HumRead -> TempHumSensorC.HumRead;


}
