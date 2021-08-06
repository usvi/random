#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/types.h>

#define SSHGUARD_BINARY "/usr/sbin/sshguard"
#define SSHGUARD_WHITELIST_SWITCH "-w"
#define BUF_SIZE 256

int main(int argc, char *argv[])
{
  char sBuf[BUF_SIZE] = { 0 };
  char sIpBuf[BUF_SIZE] = { 0 };
  char* sPointer = NULL;
  struct sockaddr_in sa;
  int iTemp = 0;
  uid_t xOriginalUid = 0xDEADBEEF;

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

  // Assemble the final binary and call it
  memset(sBuf, 0, BUF_SIZE);
  iTemp = snprintf(sBuf, BUF_SIZE, "%s %s %s", SSHGUARD_BINARY, SSHGUARD_WHITELIST_SWITCH, sIpBuf);

  if ((iTemp < 0) || (sBuf[BUF_SIZE - 1] != 0))
  {
    printf("%s : Failed to assemble whitelist command\n", argv[0]);

    return 1;
  }
  printf("%s\n", sBuf);
  xOriginalUid = getuid();
  setuid(0);
  iTemp = system(sBuf);
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
