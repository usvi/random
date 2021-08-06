#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/file.h>

#define SSHGUARD_WHITELIST_FILE "/etc/sshguard/whitelist"
#define SSHGUARD_RESTART_PROC "/usr/sbin/service sshguard restart"
#define BUF_SIZE 256
#define OP_OK 1
#define OP_FAIL 0

int whitelist_file_num_duplicates(char* sIpBuf);
int whitelist_file_add(char* sIpBuf);

int whitelist_file_num_duplicates(char* sIpBuf)
{
  
}


int whitelist_file_add(char* sIpBuf)
{
  FILE* pWhiteFile = NULL;
  int iTemp = 0;
  int iErrors = 0;

  pWhiteFile = fopen(SSHGUARD_WHITELIST_FILE, "a");

  if (pWhiteFile == NULL)
  {
    iErrors++;
  }
  if (iErrors == 0)
  {
    iTemp = flock(fileno(pWhiteFile), LOCK_SH);

    if (iTemp != 0)
    {
      fclose(pWhiteFile);
      iErrors++;
    }
  }
  if (iErrors == 0)
  {
    iTemp = fprintf(pWhiteFile, "%s\n", sIpBuf);

    if (iTemp < 0)
    {
      fclose(pWhiteFile);
      iErrors++;
    }
  }
  fclose(pWhiteFile);

  if (iErrors == 0)
  {
    return OP_OK;
  }

  return OP_FAIL;
}

int main(int argc, char *argv[])
{
  char sBuf[BUF_SIZE] = { 0 };
  char sIpBuf[BUF_SIZE] = { 0 };
  char* sPointer = NULL;
  struct sockaddr_in sa;
  int iTemp = 0;
  uid_t xOriginalUid = 0xDEADBEEF;
  int iErrors = 0;

  // No arguments needed, getting it from environment variable
  // $SSH_CLIENT which has the following form for ipv4
  // 91.158.138.210 56232 22
  
  sPointer = getenv("SSH_CLIENT");

  if (sPointer == NULL)
  {
    printf("%s : Not in SSH session\n", argv[0]);

    return 1;
  }
  memset(sIpBuf, 0, BUF_SIZE);
  strncpy(sIpBuf, sPointer, BUF_SIZE);

  if (sIpBuf[BUF_SIZE - 1] != 0)
  {
    printf("%s : Unexpected size for SSH_CLIENT environment variable\n", argv[0]);

    return 1;
  }
  sPointer = strstr(sIpBuf, " ");

  if (sPointer == NULL)
  {
    printf("%s : Garbage in SSH_CLIENT environment variable\n", argv[0]);

    return 1;
  }
  // Buffer is good, but safest to null rest
  memset(sPointer, 0, BUF_SIZE - (sPointer - sIpBuf));
  
  // Validate
  iTemp = inet_pton(AF_INET, sIpBuf, &(sa.sin_addr));

  // 1 is only successful result value.
  if (iTemp != 1)
  {
    printf("%s : Malformed IP got: %s\n", argv[0], sIpBuf);

    return 1;
  }

  // This is stupid. Sshguard as of 2021-08-06 does not add the host
  // to filelist. Should make a patch...
  xOriginalUid = getuid();
  setuid(0);

  //iTemp = system(sBuf);
  setuid(xOriginalUid);




  
  if (iTemp == 0)
  {
    printf("%s : Successfully whitelisted %s in SshGuard\n", argv[0], sIpBuf);

    return 0;
  }
  else
  {
    printf("%s : Failed to whitelist %s in SshGuard\n", argv[0], sIpBuf);

    return 1;
  }
      
    
  

  return 1;
}
