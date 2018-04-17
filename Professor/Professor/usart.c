#include "usart.h"

void USART_Init( 
    unsigned int ubrr
)
{
    //Set baud rate
    UBRR0H = (unsigned char)(ubrr>>8);
    UBRR0L = (unsigned char)ubrr;
    
    //Enable receiver and transmitter   
    UCSR0B = (1<<RXEN0)|(1<<TXEN0);

    //Set frame format: 8data, 2stop bit
    UCSR0C = (1<<URSEL0)|(1<<USBS0)|(3<<UCSZ00);
}

void USART_Transmit( 
    const char *pData,
    bool lineBreak
)
{
    while (*pData != NULL)        
    {
        USART_Transmit_Byte(*pData);
        pData++;
    }   
    
    if (true == lineBreak)
        USART_Transmit("\r\n", false);     
}

void USART_Transmit_Byte( 
    byte b
)
{
    // While data empty register is 0
    while ( (UCSR0A & (1<<UDRE0)) == 0 )
    {}

    //Put data into buffer, sends the data
    UDR0 = b;
}