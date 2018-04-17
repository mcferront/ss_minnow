/*
* Professor.c
*
* Created: 10/12/2017 9:57:14 PM
* Author : trapper.mcferron
*/

#include "system.h"
#include "professor_types.h"
#include "usart.h"

#define VERSION      0.1
#define SYSTEM_NAME  "Professor"
#define _SZ(a) #a
#define SZ(a)  _SZ(a)

#define BAUD 9600
#define MYUBRR FOSC/16/BAUD-1

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

typedef struct _Cache
{
   byte buffer[COMMAND_BUFFER_SIZE];

}Cache;

Cache g_cache;
byte g_num_controller_reads = 0;

const char *ByteToAscii(
   byte v
);

bool IsDebugPinLow( void );

void _InternalMemoryCheck( void );
void _ExternalMemoryCheck( void );

void Gilligan_AcquireBus( 
   bool waitForGilligan
   );

void Gilligan_ReleaseBus( void );

void SetupLED( void );
void SetupXMEM( void );
void SetupGilligan( void );
void SetupGinger( void );

void Gilligan_Go( void );
void Ginger_Go( void );

void Gilligan_SignalNMI( void );

void Gilligan_Update( void );

void Gilligan_Print( void );

void RunDebugRoutine( void );

void SetupController( void );
byte ReadController( void );

int main(void)
{
   cli();

   //Allow all circuits to start up
   _delay_ms(10);

   USART_Init(MYUBRR);
   
   for (int i = 0; i < 80; i++)
      USART_Transmit(" ", true);
   
   USART_Transmit("---"SYSTEM_NAME" Version: "SZ(VERSION)"---", true);
   USART_Transmit("POST...", true);
   USART_Transmit("Stack: 0x", false);
   USART_Transmit(ByteToAscii(SPH), false);
   USART_Transmit(ByteToAscii(SPL), true);
   USART_Transmit("Cache: 0x", false);

   unsigned int a = (unsigned int) &g_cache.buffer[sizeof(g_cache.buffer) - 1];
   USART_Transmit(ByteToAscii((a >> 8) & 0xff), false);
   USART_Transmit(ByteToAscii((a >> 0) & 0xff), true);

   SetupXMEM( );
   SetupGilligan( );
   SetupGinger( );
   SetupController( );

   RunDebugRoutine( );
   
   Gilligan_AcquireBus( false );
   {
      g_cache.buffer[0] = COMMAND_ID_END;
      g_cache.buffer[sizeof(g_cache.buffer) - 1] = 0;
   
      *((volatile byte *) COMMAND_START_ADDR) = COMMAND_ID_END;
      
	  Gilligan_ReleaseBus( );
   }
   
   USART_Transmit("Beginning Program Loop...", true);

   // ready...set...
   _delay_ms(1);

   Gilligan_Go( );
   Ginger_Go( );

   // go
   SetupLED( );

   //enable interrupts
   sei();

   while (true)
   {
      Gilligan_Print( );
   }
}

void Gilligan_Print( void )
{
   byte *pBuffer = g_cache.buffer;

   if ( COMMAND_ID_END != *pBuffer )
   {
      while ( *pBuffer != COMMAND_ID_END &&
              (pBuffer - g_cache.buffer) < COMMAND_BUFFER_SIZE )
      {
         if ( COMMMAND_ID_STRING == *pBuffer )
         {
            USART_Transmit((char *) (pBuffer + 1), true);
            
            while ( *pBuffer != NULL && (pBuffer - g_cache.buffer) < COMMAND_BUFFER_SIZE )
               ++pBuffer;

            ++pBuffer;
         }
         else if ( COMMMAND_ID_CONTROLLER == *pBuffer ) //not currently used
         {
            g_num_controller_reads = *(pBuffer + 1);
            pBuffer += 2;
            
            if ( IsDebugPinLow( ) )
            {
               USART_Transmit((char *) "Received ID_CONTROLLER: ", false);
               USART_Transmit((char *) ByteToAscii(g_num_controller_reads), true);               
            }               
         }
      }                     
   
      g_cache.buffer[0] = COMMAND_ID_END;
   }      
}   

void Gilligan_Update( void )
{
   if ( g_cache.buffer[0] == COMMAND_ID_END )
   {
      Gilligan_AcquireBus( true );
      {
         // debug hold
         //while ( IsDebugPinLow( ) ) {};
         { 
            volatile byte *pCommand = (volatile byte *) COMMAND_START_ADDR;
      
            byte *pDest = g_cache.buffer;
     
            do
            {
               *pDest = *pCommand;
		   
		         if ( *pCommand == COMMAND_ID_END )
		            break;
			   
               pCommand++;
		         pDest++;
            }
            while ( (pDest - g_cache.buffer) < COMMAND_BUFFER_SIZE );
         }
            
         *((volatile byte *) COMMAND_START_ADDR) = COMMAND_ID_END;         
         *((volatile byte *) CONTROLLER_START_ADDR) = ReadController( );

         Gilligan_ReleaseBus( );
      }
         
      Gilligan_SignalNMI( );
   }
}   

// Ginger finished a frame...
// Grab the bus from Gilligan
// read any queued commands
// write controller data
// Allow Gilligan to continue
ISR(INT0_vect)
{
   Gilligan_Update( );
}

// LED blink
ISR(TIMER1_COMPA_vect)
{
   static int alt;

   if (alt)
      PORTD |= (1 << PORTD4);
   else
      PORTD &= ~(1 << PORTD4);

   alt = alt ^ 1;
}

const char *ByteToAscii(
   byte v
)
{
   static char buf[3];
   
   char table[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
   buf[0] = table[(v >> 4 & 0x0f)];
   buf[1] = table[(v >> 0 & 0x0f)];
   buf[2] = 0;
   
   return buf;
}

void Gilligan_AcquireBus( bool waitForGilligan )
{
   if ( true == waitForGilligan )
   {
      //write high
      PORTC |= (1 << PORTC5);

	   // Wait until SYNC/MLB/PC5 are high, which makes our NAND low
      while ( (PINC & (1 << PINC4)) != 0 ) {}
   }
      
   PORTC &= ~(1 << PORTC7);
   
   _NOP();
}

void Gilligan_ReleaseBus( )
{
   PORTC |= (1 << PORTC7);

   _NOP();

   //write low, releasing NAND low and thus READY
   PORTC &= ~(1 << PORTC5);

   _NOP();
}

void Gilligan_Reset( void )
{
   PORTC &= ~(1 << PORTC6);

   _NOP();
}

void Gilligan_Go( void )
{
   PORTC |= (1 << PORTC6);

   _NOP();
}

void Gilligan_SignalNMI( void )
{
   PORTE |= (1 << PORTE0);

   _NOP();

   PORTE &= ~(1 << PORTE0);

   _NOP();
}

void Ginger_Reset( void )
{
}

void Ginger_Go( void )
{
}

void _ExternalMemoryCheck( void )
{
   USART_Transmit("External Memory Check...", false);
   {
      Gilligan_AcquireBus( false );

      unsigned int i;
      byte v = 1;

      for (i = XMEM_START_ADDR; i <= XMEM_END_ADDR; i++)
      {
         *((volatile byte *) i) = v;
         v = v + 1;
      }

      v = 1;
      for (i = XMEM_START_ADDR; i <= XMEM_END_ADDR; i++)
      {
         byte value = *((volatile byte *) i);

         if (value != v)
         {
            USART_Transmit("", true);
            USART_Transmit("Fail: ", false);
            USART_Transmit(ByteToAscii(v), false);
            USART_Transmit(" != ", false);
            USART_Transmit(ByteToAscii(value), true);
            break;
         }

         v = v + 1;
      }

      if (i == XMEM_END_ADDR + 1)
         USART_Transmit("Success!", true);

      Gilligan_ReleaseBus( );
   }
}

void _InternalMemoryCheck( void )
{
   USART_Transmit("Internal Memory Check...", false);
   {
      unsigned int i;
      volatile byte v = 1;
      
      for (i = 0; i < sizeof(g_cache.buffer); i++)
      {
         g_cache.buffer[i] = v;
         v = v + 1;
      }

      v = 1;
      for (i = 0; i < sizeof(g_cache.buffer); i++)
      {
         byte value =  g_cache.buffer[i];
         if (value != v)
         {
            USART_Transmit("", true);
            USART_Transmit("Fail: ", false);
            USART_Transmit(ByteToAscii(v), false);
            USART_Transmit(" != ", false);
            USART_Transmit(ByteToAscii(value), true);
            break;
         }

         v = v + 1;
      }

      if (i == sizeof(g_cache.buffer))
         USART_Transmit("Success!", true);
   }
}

void SetupXMEM( void )
{
   USART_Transmit("Enabling XMEM...", true);
      
   //External memory
   MCUCR |= 1 << SRE;

   //PC3 - PC7 set free, we use PC0-PC2 for xmem
   SFIOR |= 1 << XMM2 | 1 << XMM0;

   _NOP();
}

void SetupLED( void )
{
   //Clock timer
   //Timer 1 control register B
   //divide it by 256
   TCCR1B |= (1<<CS12);

   //Output compare register
   //When it matches the counter value
   //an interupt is fired
   //Once a second because 31250 * 256 == 8mhz
   //OCR1A = 31250;
   
   //2 times a second
   //OCR1A = 31250 / 2;

   //30 times  a second because 1041 * 256 == 266496 (266496 * 30) ~= 8mhz
   OCR1A = 1041;

   //Put timer int the compare mode
   TCCR1B |= 1 << WGM12;
      
   //Enable the match interrupt
   TIMSK |= 1 << OCIE1A;
      
   //port d pin 4 configure as output (LED status light)
   DDRD |= (1 << DDD4);

   // turn on light
   PORTD |= (1 << PORTD4);
}

void SetupGilligan( void )
{
   //port e pin 0 for gilligan NMI
   DDRE |= (1 << DDE0);
   
   //port c pin 7 configure as output (bus switch, gilligan ready, gilligan be)
   DDRC |= (1 << DDC7);

   //port c pin 6 gilligan reset
   DDRC |= (1 << DDC6);

   //port c pin 5 SYNC request low
   DDRC |= (1 << DDC5);

   //port c pin 4 check for MLB low on gilligan
   DDRC &= ~(1 << DDC4);
   PORTC |= 1 << PORTC4;

   _NOP();

   //hold nmi low until we signal it
   PORTE &= ~(1 << PORTE0);

   Gilligan_Reset( );
}

void SetupGinger( void )
{
   //clear any queued interrupt
   GIFR |= 1 << INTF0;

   //configure int0
   GICR |= 1 << INT0;
      
   //set INT0 to fire on falling edge
   //Ginger finished a frame
   MCUCR &= ~(1 << ISC00);   MCUCR |= 1 << ISC01;   
   DDRD &= ~(1 << DDD2);
   PORTD |= 1 << PORTD2; //turn on pull-up resister
   
   _NOP();
}

void SetupController( void )
{
   // pin B0-B5
   DDRB &= ~(1 << DDB0);
   DDRB &= ~(1 << DDB1);
   DDRB &= ~(1 << DDB2);
   DDRB &= ~(1 << DDB3);
   DDRB &= ~(1 << DDB4);
   DDRB &= ~(1 << DDB5);
   
   //pull up resistors
   PORTB |= 1 << PORTB0;
   PORTB |= 1 << PORTB1;
   PORTB |= 1 << PORTB2;
   PORTB |= 1 << PORTB3;
   PORTB |= 1 << PORTB4;
   PORTB |= 1 << PORTB5;  

   // select pin high
   DDRB |= (1 << DDB6);
   PORTB |= (1 << PORTB6);
}

void RunDebugRoutine( void )
{
   bool do_debug_post = 0;

   // Debug check
   if (true)
   {
      USART_Transmit("Checking Debug Pin: 0x", false);
      
      // pin D5 as input
      DDRD &= ~(1 << DDD5);
      PORTD |= 1 << PORTD5;

      _NOP();

      USART_Transmit(ByteToAscii(PIND), true);

      // read the value
      do_debug_post = IsDebugPinLow( );
   }

   if (0 != do_debug_post)
   {
      USART_Transmit("Debug Pin Detected, Starting Debug Test...", true);

      _InternalMemoryCheck( );
      _ExternalMemoryCheck( );
   }
}

bool IsDebugPinLow( void )
{
   return (PIND & (1 << PIND5)) == 0;  
}   

byte ReadController( void )
{
      //B6  LOW      HIGH
      //-----------------
      //B0  Up       Up
      //B1  Down     Down
      //B2  -        Left
      //B3  -        Right
      //B4  A        B
      //B5  Start    C
      //byte pin, status;
      //
      ////pull select low
      PORTB &= ~(1 << PORTB6);
      _NOP();

      byte pin, status;

      pin = PINB;
      status = 0;
      
      if ( (pin & (1 << PINB2)) == 0 )
         status |= CONTROLLER_LEFT;
      if ( (pin & (1 << PINB3)) == 0 )
         status |= CONTROLLER_RIGHT;
      if ( (pin & (1 << PINB4)) == 0 )
         status |= CONTROLLER_B;
      if ( (pin & (1 << PINB5)) == 0 )
         status |= CONTROLLER_C;
      
      // pull select high
      PORTB |= 1 << PORTB6;
      _NOP();

      pin = PINB;

      if ( (pin & (1 << PINB0)) == 0 )
         status |= CONTROLLER_UP;
      if ( (pin & (1 << PINB1)) == 0 )
         status |= CONTROLLER_DOWN;
      if ( (pin & (1 << PINB4)) == 0 )
         status |= CONTROLLER_A;
      if ( (pin & (1 << PINB5)) == 0 )
         status |= CONTROLLER_START;
         
      return status;
 }   