#define _CRT_SECURE_NO_WARNINGS
#define NAME   "GilliganCC"

#include <fcntl.h>  
#include <io.h>  
#include <stdio.h>
#include <malloc.h>
#include <string.h>

void main( int count, const char *pArg[ ] )
{
   do
   {
      if ( count < 2 )
      {
         fprintf( stderr, NAME": No input file specified" );
         break;
      }

      const char *pFile = pArg[ 1 ];
      int fh = _open( pFile, _O_RDWR, 0 );
      if ( -1 == fh )
      {
         fprintf( stderr, NAME": Invalid file: %s", pFile );
         break;
      }

      _chsize( fh, 0x8000 );

      _close( fh );

   } while ( 0 );
}