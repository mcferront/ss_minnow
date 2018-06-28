Mistake 1: gfx port on vsync was wired to clk
Mistake 2: need a reset pin from prof to gfx

next steps
----
   0. remove obslete 3v testing code and 3v pin code
   1. mary ann dac palette color bars
      DAC - www.analog.com/media/en/technical-documentation/data-sheets/AD7302.pdf
         85:  0101 0101 GN LO
         170: 1010 1010 GN HI
         255: 1111 1111 

   Document Ocean pipeline + specs
   Breadboard Mary Ann
   Design Ginger
   
Codenames:
   SS Minnow: The console
   
   The Island: Motherboard
      Professor (ATMega): The utility/peripheral/everything chip on The Island
      Gilligan (6502): Runs the cartridge code

   The Ocean: Graphics board
      Ginger (ATMega?): The display list interpreter and scan line buffer manager
      Mary Ann (ATmega?): The scan line buffer to video out chip 

   
links
---
http://www.ti.com/lit/ds/symlink/sn74hc32.pdf
http://www.mouser.com/ds/2/436/w65c02s-2572.pdf
http://www.ti.com/lit/ds/symlink/sn74ahct573.pdf
http://www.ti.com/lit/ds/symlink/sn74cbtd16211.pdf
http://www.tij.co.jp/jp/lit/ds/scds033e/scds033e.pdf
http://ww1.microchip.com/downloads/en/devicedoc/atmel-2513-8-bit-avr-microntroller-atmega162_datasheet.pdf
http://www.mouser.com/ds/2/268/doc0006-1066077.pdf
http://www.cypress.com/file/42836/download
http://www.nteinc.com/specs/7400to7499/pdf/nte74s00.pdf
http://www.mouser.com/ds/2/3/aco-514121.pdf
adz24: https://www.digikey.com/product-detail/en/analog-devices-inc/ad724jrz/ad724jrz-nd/653959
3.58mhz clock https://www.digikey.com/scripts/dksearch/dksus.dll?detail&itemseq=262437742&uq=636633277738425485

parts
---
RS232: https://www.digikey.com/scripts/DkSearch/dksus.dll?Detail&itemSeq=260934583&uq=636620306589871118
GFX: https://www.digikey.com/scripts/DkSearch/dksus.dll?Detail&itemSeq=260935529&uq=636620308485770689
RX/TX: https://www.digikey.com/scripts/DkSearch/dksus.dll?Detail&itemSeq=260935232&uq=636620306589881119
power: https://www.digikey.com/scripts/DkSearch/dksus.dll?Detail&itemSeq=260935383&uq=636620306589881119


voltage divider: v * r2 / (r1 + r2)
capacitance calc: 2*CL - 2*CStray (CStray estimated at 5pf)

descriptions
  
   
Advice from Chris
   better bypass cap lines
   matching trace lines
 

Island - High Level
----
GIL 
   executes 6502 code
   Sends utility function requests to PROF 
   uploads tile indices to GING
   reads controller data from PROF

PROF 
   handles utility requests from GIL
   DEBUG IO
   reads controller data, formats it for GIL

 

Island - Mid Level
----
PROF
   PROF resets GIL
   PROF listens for VSYNC from GING
   Each VSYNC
      acquires bus
      Reads/handles command packets from GIL
      writes controller data for GIL
      releases bus

 
GIL
   Runs code off the ROM
   writes command packets to PROF (if needed)
   Each NMI 
      Reads controller data from shared mem
   Uploads tile indices to GING

 
PROF - Details

---
PROF starts up
   Initializes Serial Output (SO)
   Transmits post data on SO
   Sets up external memory access for PC0-PC2
   Holds GIL NMI low
   Holds GIL RESB low
   Initializes shared MEM
   Pulls GIL RESB high (GIL runs)
   Sets up LED
   Watchdog for 30hz
   PROF loop
   Print string to SO if COMMAND_ID_STRING received

GIL ports...
   PE0 OUT: for GIL NMI
   PC7 OUT: BS1-1 E, BS1-2 E, BS2-2 E, GIL READY, GIL BE
   PC6 OUT: GIL RESB
   PC5 OUT: BUS REQ
   PC4 IN: GIL SYNC/GIL MLB/BUS REQ

GING ports...
   INT0 IN: falling edge

CNTRL ports...
   B0-B5 IN
 
PROF on GING INT
   Acquire Bus
   Requests bus (PC5 High)
   Waits for GIL Stall (PC4 high)
   Opens bus (PC7 low)
   Reads packets from COMMAND_START_ADDR
   Writes CNTRL to CONTROLLER_START_ADDR
   Release Bus (PC7 low, PC5 low)
   Signals GIL NMI (PE0 high, nop, PE0 low)

 
PROF/GIL SHARED MEM MAPPING
   PROF has it mapped to 0x0600-0x06ff but lines higher than 0x0400 are pulled low
      So the physical addr is 0x0200-0x02ff
      It can't be 0x0200-0x2ff directly in PROF because that maps to internal RAM
   
   GIL uses physical memory 0x0200-0x02ff


GIL - Details (Up to the cartridge)
----
   Listens for NMI
   Reads controller data
   Writes input received to debug out for professor



 

 

 