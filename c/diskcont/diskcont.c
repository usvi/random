#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/ioctl.h>
#include <linux/fs.h>
#include <time.h>

// gcc -D_FILE_OFFSET_BITS=64 -Wall -o diskcont diskcont.c

#define DC_GEN_BUF_SIZE ((uint32_t)(2000))

#define DC_RUNNING_NUM_SIZE_BYTES ((uint32_t)(8))
#define DC_BUF_SIZE_KIBIBYTE (((uint32_t)(128)) * DC_RUNNING_NUM_SIZE_BYTES)
#define DC_BUF_SIZE_MEBIBYTE (((uint32_t)(1024)) * DC_BUF_SIZE_KIBIBYTE)
#define DC_BUF_SIZE_COMPLETE (((uint32_t)(100)) * DC_BUF_SIZE_MEBIBYTE)

typedef struct
{
  uint8_t u8Silent;
  uint8_t u8Write;
  uint8_t u8Read;
  char sDevice[DC_GEN_BUF_SIZE];
  uint64_t u64DevSizeBytes;
  
} tDcState;


static uint8_t bDC_GetParams(int argc, char* argv[], tDcState* pxState)
{
  uint8_t i;
  uint8_t u8WriteFound = 0;
  uint8_t u8ReadFound = 0;

  // Default settings
  pxState->u8Silent = 0;
  pxState->u8Write = 1;
  pxState->u8Read = 1;

  memset(pxState->sDevice, 0, DC_GEN_BUF_SIZE);

  if (argc < 2)
  {
    // Device not given and argc generally too small
    return 0;
  }

  for (i = 1; i < (argc - 1); i++)
  {
    if (strcmp("-r", argv[i]) == 0)
    {
      u8ReadFound = 1;
    }
    else if (strcmp("-w", argv[i]) == 0)
    {
      u8WriteFound = 1;
    }
    else if (strcmp("-s", argv[i]) == 0)
    {
      pxState->u8Silent = 1;
    }
    else
    {
      // Wrong parameter
      
      return 0;
    }

  }
  if (u8WriteFound + u8ReadFound)
  {
    // Default setting invalid
    pxState->u8Write = 0;
    pxState->u8Read = 0;
    // New setting
    pxState->u8Write = u8WriteFound;
    pxState->u8Read = u8ReadFound;
  }

  if ((strcmp(argv[argc - 1], "-r") == 0) ||
      (strcmp(argv[argc - 1], "-w") == 0) ||
      (strcmp(argv[argc - 1], "-s") == 0))
  {
    // No device given
    return 0;
  }
  // Device given.
  strcpy(pxState->sDevice, argv[argc - 1]);

  return 1;
}



static void DC_PrepareBuffer(void* pBufMem,
			     uint64_t u64AvailBufSizeBytes,
			     uint64_t u64DataLeftBytes,
			     uint64_t u64StartNumber,
			     uint64_t* pu64UsedDataBytes,
			     uint64_t* pu64UsedNumbers)
{
  // Staticed here just for efficiency
  static uint64_t u64BytesToWrite;
  static uint64_t u64NumNumbers;
  static uint64_t u64LeftoverBytes;
  static uint64_t u64WriteNum;
  static void* pMemUpperBound;
  
  memset(pBufMem, 0, u64AvailBufSizeBytes);
  // Pick smaller amount of full buffer and data left
  u64BytesToWrite = ((u64AvailBufSizeBytes < u64DataLeftBytes) ? u64AvailBufSizeBytes : u64DataLeftBytes);
  u64NumNumbers = u64BytesToWrite / DC_RUNNING_NUM_SIZE_BYTES;
  u64LeftoverBytes = u64BytesToWrite % DC_RUNNING_NUM_SIZE_BYTES;
  pMemUpperBound = pBufMem + (u64NumNumbers * DC_RUNNING_NUM_SIZE_BYTES);
  u64WriteNum = u64StartNumber;

  while (pBufMem < pMemUpperBound)
  {
    memcpy(pBufMem, &u64WriteNum, DC_RUNNING_NUM_SIZE_BYTES);
    u64WriteNum++;
    pBufMem += DC_RUNNING_NUM_SIZE_BYTES;
  }
  if (u64LeftoverBytes)
  {
    memcpy(pBufMem, &u64WriteNum, u64LeftoverBytes);
    u64WriteNum++;
  }
  *pu64UsedDataBytes = u64BytesToWrite;
  *pu64UsedNumbers = u64WriteNum - u64StartNumber;
}


static void DC_PrintProgress(uint64_t u64PassedBytes,
			     uint64_t u64FinalSize,
			     time_t tPassedTime)
{
  static uint32_t u32TimeElapsed;
  static uint32_t u32Secs;
  static uint32_t u32Mins;
  static uint32_t u32Hours;
  static float fProgress;

  u32TimeElapsed = tPassedTime;
  u32Secs = u32TimeElapsed % 60;
  u32TimeElapsed -= u32Secs;
  u32Mins = (u32TimeElapsed % 3600) / 60;
  u32TimeElapsed -= u32Mins * 60;
  u32Hours = u32TimeElapsed / 3600;

  fProgress = 100.0 * ((float)(u64PassedBytes)) / ((float)(u64FinalSize));


  printf("\rAt position %" PRIu64 " bytes / %" PRIu64 " bytes, %02.2f%%, "
	 "elapsed time: %uh %02um %02us",
	 u64PassedBytes, u64FinalSize, fProgress,
	 u32Hours, u32Mins, u32Secs);
  fflush(stdout);
}





static uint8_t bDC_ReadTest(tDcState* pxState)
{
  void* pCompBufMem = NULL;
  void* pReadBufMem = NULL;
  int iFd = -1;
  time_t tStartTime;
  time_t tLastTime;
  time_t tNowTime;
  uint64_t u64DataLeftBytes = pxState->u64DevSizeBytes;
  uint64_t u64ReadNumber = 0;
  uint64_t u64BufferUsedDataBytes = 0;
  uint64_t u64BufferUsedNumbers = 0;
  uint64_t u64ReadCallBytes = 0;

  tStartTime = time(NULL);
  tLastTime = time(NULL) - 5; // Ensure at least 5 print

  
  pCompBufMem = malloc(DC_BUF_SIZE_COMPLETE);

  if (pCompBufMem == NULL)
  {
    printf("Error: Malloc failed\n");
    
    return 0;
  }
  pReadBufMem = malloc(DC_BUF_SIZE_COMPLETE);

  if (pReadBufMem == NULL)
  {
    free(pCompBufMem);

    printf("Error: Malloc failed\n");

    return 0;
  }
  
  //iFd = open(pxState->sDevice, O_RDONLY | O_SYNC);
  iFd = open(pxState->sDevice, O_RDONLY);

  if (iFd == -1)
  {
    printf("Error: Unable to open the device in write mode\n");
    free(pCompBufMem);
    free(pReadBufMem);

    return 0;
  }

  // In loop prepare the buffer, read and compare
  while (u64DataLeftBytes)
  {
    DC_PrepareBuffer(pCompBufMem, DC_BUF_SIZE_COMPLETE,
		     u64DataLeftBytes,
		     u64ReadNumber,
		     &u64BufferUsedDataBytes,
		     &u64BufferUsedNumbers);
    
    u64ReadCallBytes = read(iFd, pReadBufMem, u64BufferUsedDataBytes);
  
    if (u64ReadCallBytes != u64BufferUsedDataBytes)
    {
      printf("Error: Problem reading bytes %" PRIu64 "\n", (pxState->u64DevSizeBytes - u64DataLeftBytes));
      free(pCompBufMem);
      free(pReadBufMem);
      close(iFd);
    
      return 0;
    }
    // Compare buffers
    if (memcmp(pCompBufMem, pReadBufMem, u64BufferUsedDataBytes) != 0)
    {
      printf("\nError: Comparing failed at byte %" PRIu64 "\n",
	     (pxState->u64DevSizeBytes - u64DataLeftBytes));
      free(pCompBufMem);
      free(pReadBufMem);
      close(iFd);
    
      return 0;
    }
    
    u64DataLeftBytes -= u64BufferUsedDataBytes;
    u64ReadNumber += u64BufferUsedNumbers;

    // Write where we are, if 5 seconds passed
    tNowTime = time(NULL);

    if (tNowTime > (tLastTime + 4))
    {
      DC_PrintProgress((pxState->u64DevSizeBytes - u64DataLeftBytes),
		       pxState->u64DevSizeBytes, (tNowTime - tStartTime));
      tLastTime = tNowTime;
    }
  }
  tNowTime = time(NULL);
  DC_PrintProgress((pxState->u64DevSizeBytes - u64DataLeftBytes),
		   pxState->u64DevSizeBytes, (tNowTime - tStartTime));
  printf("\nDone reading, compare OK!\n");
  
  free(pCompBufMem);
  free(pReadBufMem);
  close(iFd);

  return 1;
}





static uint8_t bDC_WriteTest(tDcState* pxState)
{
  void* pBufMem = NULL;
  int iFd = -1;
  time_t tStartTime;
  time_t tLastTime;
  time_t tNowTime;
  uint64_t u64DataLeftBytes = pxState->u64DevSizeBytes;
  uint64_t u64WriteNumber = 0;
  uint64_t u64BufferUsedDataBytes = 0;
  uint64_t u64BufferUsedNumbers = 0;
  uint64_t u64WrittenCallBytes = 0;

  tStartTime = time(NULL);
  tLastTime = time(NULL) - 5; // Ensure at least 5 print

  
  pBufMem = malloc(DC_BUF_SIZE_COMPLETE);

  if (pBufMem == NULL)
  {
    printf("Error: Malloc failed\n");
    
    return 0;
  }
  // FIXME: Correct additional flags
  //iFd = open(pxState->sDevice, O_WRONLY | O_SYNC);
  iFd = open(pxState->sDevice, O_WRONLY);

  if (iFd == -1)
  {
    printf("Error: Unable to open the device in write mode\n");
    free(pBufMem);

    return 0;
  }

  // In loop prepare the buffer and write
  while (u64DataLeftBytes)
  {
    DC_PrepareBuffer(pBufMem, DC_BUF_SIZE_COMPLETE,
		     u64DataLeftBytes,
		     u64WriteNumber,
		     &u64BufferUsedDataBytes,
		     &u64BufferUsedNumbers);
    
    u64WrittenCallBytes = write(iFd, pBufMem, u64BufferUsedDataBytes);
  
    if (u64WrittenCallBytes != u64BufferUsedDataBytes)
    {
      printf("Error: Problem writing bytes %" PRIu64 "\n", (pxState->u64DevSizeBytes - u64DataLeftBytes));
      free(pBufMem);
      close(iFd);
    
      return 0;
    }
    u64DataLeftBytes -= u64BufferUsedDataBytes;
    u64WriteNumber += u64BufferUsedNumbers;

    // Write where we are, if 5 seconds passed
    tNowTime = time(NULL);

    if (tNowTime > (tLastTime + 4))
    {
      DC_PrintProgress((pxState->u64DevSizeBytes - u64DataLeftBytes),
		       pxState->u64DevSizeBytes, (tNowTime - tStartTime));
      tLastTime = tNowTime;
    }
  }
  tNowTime = time(NULL);
  DC_PrintProgress((pxState->u64DevSizeBytes - u64DataLeftBytes),
		   pxState->u64DevSizeBytes, (tNowTime - tStartTime));
  printf("\nSyncinc...\n");
  fsync(iFd);
  printf("Done all writing!\n");
  
  free(pBufMem);
  close(iFd);

  return 1;
}




int main(int argc, char* argv[])
{
  int iFd = -1;
  int iTemp = 0;
  tDcState xState;
  char sReadBuf[DC_GEN_BUF_SIZE] = { 0 };
  
  if (!bDC_GetParams(argc, argv, &xState))
  {
    printf("Error: Params failure, use:\n");
    printf("diskcont [-w] [-r] [-s] /path/to/device\n");

    return 1;
  }
  iFd = open(xState.sDevice, O_RDONLY);

  if (iFd == -1)
  {
    printf("Error: Unable to open device %s (are you root?)\n", xState.sDevice);
    
    return 1;
  }
  iTemp = ioctl(iFd, BLKGETSIZE64, &(xState.u64DevSizeBytes));
  close(iFd);

  if (iTemp == -1)
  {
    printf("Error: Unable to get size of the device (%s)!\n", xState.sDevice);
    
    return 1;
  }

  if (xState.u8Write)
  {
    // Write test
    if (!xState.u8Silent)
    {
      printf("This write test will COMPLETELY WIPE OUT %s\n", xState.sDevice);
      printf("To continue, type uppercase yes\n");
      fgets(sReadBuf, sizeof(sReadBuf), stdin);

      if (strncmp(sReadBuf, "YES", strlen("YES")) != 0)
      {
	printf("Error: User failed to confirm operation\n");
	
	return 1;
      }
    }
    if (!bDC_WriteTest(&xState))
    {
      return 1;
    }
  }
  if (xState.u8Read)
  {
    if (!bDC_ReadTest(&xState))
    {
      return 1;
    }
  }

  return 0;
}
