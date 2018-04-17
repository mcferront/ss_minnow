
#define true   1
#define false  0
#define byte   unsigned char
#define bool   byte
#define NULL   0

#define COMMMAND_ID_STRING       0x01
#define COMMMAND_ID_CONTROLLER   0x02
#define COMMAND_ID_END           0xff
                               

#define XMEM_START_ADDR 0x0600   // lines higher than 0x0400 are pulled low so this maps to 0x0200-0x2ff
#define XMEM_END_ADDR   0x06ff

#define CONTROLLER_SIZE       8

#define COMMAND_START_ADDR		(XMEM_START_ADDR)
#define COMMAND_BUFFER_SIZE   (0X100 - CONTROLLER_SIZE)
#define CONTROLLER_START_ADDR	(COMMAND_START_ADDR + COMMAND_BUFFER_SIZE)
#define CONTROLLER_END_ADDR	(CONTROLLER_START_ADDR + CONTROLLER_SIZE - 1)

#define CONTROLLER_UP      0x01
#define CONTROLLER_DOWN    0x02
#define CONTROLLER_LEFT    0x04
#define CONTROLLER_RIGHT   0x08
#define CONTROLLER_A       0x10
#define CONTROLLER_B       0x20
#define CONTROLLER_C       0x40
#define CONTROLLER_START   0x80

