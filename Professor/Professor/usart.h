#include "system.h"
#include "professor_types.h"

void USART_Init( 
    unsigned int ubrr
);
    
void USART_Transmit( 
    const char *pData,
    bool lineBreak
);

void USART_Transmit_Byte( 
    byte b
);
