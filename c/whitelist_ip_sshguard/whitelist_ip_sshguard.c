/*

Usage:
gcc -Wall -g whitelist_ip_sshguard.c -o whitelist_ip_sshguard
As root:
cp whitelist_ip_sshguard /usr/local/sbin
chown root:root /usr/local/sbin/whitelist_ip_sshguard
chmod u+s /usr/local/sbin/whitelist_ip_sshguard

As user
Add to .bashrc or similiar:


if [ -n "$SSH_CLIENT" ];
then
  /usr/local/sbin/whitelist_ip_sshguard
fi

*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/file.h>

#define SSHGUARD_WHITELIST_FILE "/etc/sshguard/whitelist"
#define SSHGUARD_RESTART_PROC "/usr/sbin/service sshguard restart"
#define SSHGUARD_CONF_FILE "/etc/sshguard/sshguard.conf"
#define BUF_SIZE 256
#define OP_OK 1
#define OP_FAIL 0


static int sshguardconf_get_ipv4_subnet_suffix(char* sSubnetSuffix);
static int whitelist_file_num_duplicates(const char* sIpBuf, int* piDuplicates);
static int whitelist_file_add(const char* sIpBuf);


// Gets the configured subnet format from conf file. 
// Conf:
// IPV4_SUBNET=24
// This function would get "/24". If does not exist,
// function returns empty, but it is still considered valid.
int sshguardconf_get_ipv4_subnet_suffix(char* sSubnetSuffix)
{
  FILE* pConfFile = NULL;
  char sBuf[BUF_SIZE] = { 0 };
  char* sPointer = NULL;
  int iSuffixBits = 0;
  int iRes = 0;

  // Default value is empty
  printf(sSubnetSuffix, "");
  pConfFile = fopen(SSHGUARD_CONF_FILE, "r");

  if (pConfFile == NULL)
  {
    return OP_OK;
  }

  while(!feof(pConfFile))
  {
    memset(sBuf, 0, BUF_SIZE);
    fgets(sBuf, BUF_SIZE - 1, pConfFile);
    sPointer = strstr(sBuf, "IPV4_SUBNET=");

    if (sPointer != NULL)
    {
      sPointer += strlen("IPV4_SUBNET=");
      iRes = sscanf(sPointer, "%d", &iSuffixBits);

      if (iRes == 1)
      {
	// Found, write outgoing buffer and break
	sprintf(sSubnetSuffix, "/%d", iSuffixBits);

	break;
      }
    }
  }
  fclose(pConfFile);

  return OP_OK;
}


int whitelist_file_num_duplicates(const char* sIpBuf, int* piDuplicates)
{
  FILE* pWhiteFile = NULL;
  int iTemp = 0;
  int iErrors = 0;
  char sBuf[BUF_SIZE] = { 0 };
  *piDuplicates = 0;
  char* sPointer = NULL;
  
  pWhiteFile = fopen(SSHGUARD_WHITELIST_FILE, "r");

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
    while(!feof(pWhiteFile))
    {
      memset(sBuf, 0, BUF_SIZE);
      fgets(sBuf, BUF_SIZE - 1, pWhiteFile);

      // Remove trailing newline
      sPointer = strstr(sBuf, "\n");

      if (sPointer != NULL)
      {
	// Found, null it
	*sPointer = 0;
      }
      // Now we can make comparison
      if (strncmp(sBuf, sIpBuf, BUF_SIZE) == 0)
      {
	// Got it
	(*piDuplicates)++;
      }
    }
  }
  if (iErrors == 0)
  {
    iTemp = flock(fileno(pWhiteFile), LOCK_UN);
    fclose(pWhiteFile);
  }

  if (iErrors == 0)
  {
    // piDuplicates automatically incremented
    
    return OP_OK;
  }

  return OP_FAIL;
}


int whitelist_file_add(const char* sIpBuf)
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
    iTemp = flock(fileno(pWhiteFile), LOCK_EX);

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
  if (iErrors == 0)
  {
    iTemp = flock(fileno(pWhiteFile), LOCK_UN);
    fclose(pWhiteFile);
  }

  if (iErrors == 0)
  {
    return OP_OK;
  }

  return OP_FAIL;
}

int main(int argc, char *argv[])
{
  char sIpBuf[BUF_SIZE] = { 0 };
  char sMaskSuffixBuf[BUF_SIZE] = { 0 };
  char sIpWithMaskSuffixBuf[BUF_SIZE] = { 0 };
  char* sPointer = NULL;
  struct sockaddr_in sa;
  int iTemp = 0;
  uid_t xOriginalUid = 0xDEADBEEF;
  uid_t xOriginalEuid = 0xDEADBEEF;
  int iDuplicates = 0;

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
  // Get mask from conf file and create the final buffer
  sshguardconf_get_ipv4_subnet_suffix(sMaskSuffixBuf);
  // Pseudo assignment so there is no compiler nag
  iTemp = snprintf(sIpWithMaskSuffixBuf, BUF_SIZE, "%s%s", sIpBuf, sMaskSuffixBuf);

  // This is stupid. Sshguard as of 2021-08-06 does not add the host
  // to filelist. Should make a patch...
  xOriginalEuid = geteuid();
  seteuid(0);
  iTemp = whitelist_file_num_duplicates(sIpWithMaskSuffixBuf ,&iDuplicates);
  seteuid(xOriginalEuid);

  if (iTemp == OP_FAIL)
  {
    printf("%s : Unable to search %s duplicates from whitelist %s\n", argv[0], sIpWithMaskSuffixBuf, SSHGUARD_WHITELIST_FILE);

    return 1;
  }

  if (iDuplicates > 0)
  {
    printf("%s : %s already in SshGuard whitelist %s\n", argv[0], sIpWithMaskSuffixBuf, SSHGUARD_WHITELIST_FILE);

    return 0;
  }
  if (iDuplicates == 0)
  {
    xOriginalEuid = geteuid();
    seteuid(0);
    iTemp = whitelist_file_add(sIpWithMaskSuffixBuf);
    seteuid(xOriginalEuid);
  }
  if (iTemp == OP_FAIL)
  {
    printf("%s : Unable to add %s to whitelist %s\n", argv[0], sIpWithMaskSuffixBuf, SSHGUARD_WHITELIST_FILE);

    return 1;
  }
  // If duplicates: already returned
  // If failing to add: already returned
  // Try restarting sshguard (it requires both efective and real uid to be the same

  xOriginalEuid = geteuid();
  xOriginalUid = getuid();
  seteuid(0);
  setuid(0);
  iTemp = system(SSHGUARD_RESTART_PROC);
  seteuid(xOriginalEuid);
  setuid(xOriginalUid);
  
  if (iTemp == 0)
  {
    printf("%s : Successfully whitelisted %s in SshGuard\n", argv[0], sIpWithMaskSuffixBuf);

    return 0;
  }

  printf("%s : Failed to whitelist %s in SshGuard\n", argv[0], sIpWithMaskSuffixBuf);

  return 1;

}
