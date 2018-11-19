#define INIT_TIME 5000
#define FINISH_TIME 60000

#define NUM_MSGS 10
#define SEND_PERIOD 1000
#define SEND_DELAY 5000

module TestCtpC {
  uses{
    interface Boot;

    interface Timer<TMilli> as InitTimer;
    interface Timer<TMilli> as FinishTimer;
    interface Timer<TMilli> as SendTimer;

    interface SplitControl as SerialControl;
    interface SplitControl as RadiosControl;
    interface StdControl as CtpRouteControl;

		interface SerialLogger;


    interface RootControl;
    interface CtpInfo;
    interface CollectionPacket;
    interface Receive;
    interface Intercept;
    interface Send;

  }

}


implementation {

	bool is_root;
  bool transmitting = FALSE;
  uint16_t sendCount = 0;
  uint16_t receivedCount = 0;
  message_t msgBuffer;


  void initializeNode() {

    if (TOS_NODE_ID == 6 || TOS_NODE_ID == 17 || TOS_NODE_ID == 25 || TOS_NODE_ID == 36) {
      call RootControl.setRoot();
      call SerialLogger.log(LOG_ROOT, TOS_NODE_ID);
      call FinishTimer.startOneShot(FINISH_TIME);

    } else{
      transmitting = TRUE;
      call SerialLogger.log(LOG_INITIALIZED, TOS_NODE_ID);
      call SendTimer.startPeriodicAt(SEND_DELAY, SEND_PERIOD);
      call FinishTimer.startOneShot(FINISH_TIME);
    }
  }


  void SendMessage(){
    message_t * msg;
    DataMsg * payload;
    error_t result;
    uint8_t i;
     if (NUM_MSGS > 0 && sendCount >= NUM_MSGS) {
      return;
    }
    msg = &msgBuffer;
    payload = (DataMsg*) call Send.getPayload(msg, sizeof(DataMsg));

    payload->seqno = sendCount;
    for (i = 0; i < MSG_SIZE; i++) {
      payload->data[i] = i;
    }
    result = call Send.send(msg, sizeof(DataMsg));
    if (result == SUCCESS) {
      sendCount++;
      call SerialLogger.log(LOG_SENDING,sendCount);
    }
    else{
      call SerialLogger.log(LOG_SEND_FAILED,result);
    }
  }


  event void Boot.booted(){
    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call SerialControl.start();
    } else {
      call RadiosControl.start();
    }
  }

  event void SerialControl.stopDone(error_t err) {}

  event void RadiosControl.startDone(error_t error) {
    if (error != SUCCESS) {
      call RadiosControl.start();
    } else {
      call SerialLogger.log(LOG_RADIO_START,0);
      call CtpRouteControl.start();
      call InitTimer.startOneShot(INIT_TIME);
    }
  }

	event void RadiosControl.stopDone(error_t err) {}



  event void InitTimer.fired() {
    initializeNode();
  }

  event void SendTimer.fired() {
    if (transmitting) {
      call SerialLogger.log(LOG_SEND_TIMER,1);
      SendMessage();
      if (sendCount >= NUM_MSGS) {
        transmitting = FALSE;
      }
    } else {
      call SendTimer.stop();
    }
  }

	event bool Intercept.forward(message_t *msg, void *payload, uint8_t len) {}

	event void Send.sendDone(message_t *msg, error_t error) {}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len) {
    receivedCount++;
    return msg;
  }
	

  event void FinishTimer.fired(){
    call SendTimer.stop();
		call SerialLogger.log(LOG_FINISH,TOS_NODE_ID);
    if(call RootControl.isRoot()){
      call SerialLogger.log(LOG_ROOT,TOS_NODE_ID);
      call SerialLogger.log(LOG_RECEIVED_COUNT,receivedCount);
    }
    else{
      call SerialLogger.log(LOG_NOT_ROOT,TOS_NODE_ID);
      call SerialLogger.log(LOG_SENT_COUNT,sendCount);
    }

  }

}

