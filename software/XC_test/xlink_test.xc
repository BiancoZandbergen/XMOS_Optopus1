/**
 * XMOS Link Application Layer Test
 * Author: Bianco Zandbergen 
 * 
 * This application tests the correct working of the XMOS Link
 * between two XK-1 development boards.
 * It does this by sending data over the link and back.
 * The values of the received data is checked.
 * Toggling LEDs provide a fast visual confirmation of the test.
 * 
 * Thread diagram:
 * 
 *   Core 0                 XMOS Link               Core 1
 *    
 *   Producer ------------------------------------- led_handler
 *                                             |
 *   Consumer ------                           ---- Consumer
 *                 |
 *   led_handler ---------------------------------- producer
**/

#include <xs1.h>
#include <stdio.h>
#include <platform.h>

// LED ports
on stdcore[0] : out port core0_leds = XS1_PORT_4F;
on stdcore[1] : out port core1_leds = XS1_PORT_4F;

#define DELAY 2000000 // 10ns resolution
#define USE_DELAY 0

/**
 * The producer sends integers to the consumer.
 * Both the producer and consumer increment the integer
 * with 1. After that the consumer sends the value of the integer back
 * to the producer. The producer checks if this value is the
 * same as the value of the locally calculated result.
 * If the XMOS Link is stable, the received result and the
 * locally calculated result is always the same.
 * After receiving a number of valid values the producer will toggle
 * the LEDs on the other core by sending the value of the LEDs over the
 * XMOS Link. With the LEDs one can visually confirm that the XMOS Link
 * works correctly.     
 */       
void producer(chanend c_cons, chanend c_led)
{ 
  unsigned int value = 0;
  unsigned int recv_value;
  unsigned long counter = 0;
  unsigned char led_state = 0x00;
  
  printf("Core: 0x%.4x Thread: 0x%.2X (producer)\n", get_core_id(), get_thread_id());
 
  while (1)
  {

#if (USE_DELAY == 1)
    timer t;
    unsigned time;
    
    t :> time;
    time += DELAY;
    t when timerafter(time) :> void;
#endif 

    c_cons <: value;        // send the value to the consumer
    value += 1;             // Increment of the local value
    c_cons :> recv_value;   // Receive value from the consumer
    
    if (value != recv_value) {
      printf("Received value is incorrect\n");
      while(1);
    } else {
      
      counter++;
      
      // toggle LEDs
      if ((counter % 10) == 0) {
        c_led <: led_state; // Send LED state to the LED handler on the other core
        
        switch (led_state) {
          case 0x00:
            led_state = 0x0F;
            break;
          case 0x0F:
            led_state = 0x00;
            break;
        }
      }     
    }
  }
}

/**
 * The consumer receives an integer through a channel end.
 * It adds 1 to this number and sends it back.
 */   
void consumer(chanend c)
{  
  unsigned int recv_value;

  printf("Core: 0x%.4x Thread: 0x%.2X (consumer)\n", get_core_id(), get_thread_id());
  
  while (1)
  {
    c :> recv_value;
    recv_value += 1;
    c <: recv_value;
    
  }
}

/**
 * The led_handler receives a value over a channel end
 * and writes this value to the port on which the LEDs are connected
 */  
void led_handler(chanend c, out port p)
{
  unsigned char led_state;
  
  printf("Core: 0x%.4x Thread: 0x%.2X (led_handler)\n", get_core_id(), get_thread_id());
  
  while(1) {
    c :> led_state;
    p <: led_state;
  }
}

int main()
{
  // communication channels
  chan c_data0;
  chan c_data1;
  chan c_led0;
  chan c_led1;
  
  par
  {   
    // Concurrent threads on Core 0
    on stdcore[0] : par {
                      producer(c_data0, c_led1);
                      consumer(c_data1);
                      led_handler(c_led0, core0_leds);
                    }
    
    // Concurrent threads on Core 1
    on stdcore[1] : par {
                      producer(c_data1, c_led0);
                      consumer(c_data0);
                      led_handler(c_led1, core1_leds);   
                    }
  }
  
  return 0;
}
