#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 4096

int main(int argc, char *argv[])
{
  if(argc < 3)
  {
    printf("Incorrect parameters\n");

    return 1;
  }

  struct stat rom_stat;
  int stat_result = stat(argv[1], &rom_stat);

  if(stat_result != 0)
  {
    printf("Error opening input file\n");
    
    return 0;
  }
  // Allocate an copy the search param to buffer
  char search_buf[BUF_SIZE];
  memset(search_buf, 0, BUF_SIZE);
  strncpy(search_buf, argv[2], BUF_SIZE - 1);
  // Open rom file, store results to buffer
  size_t rom_size = (rom_stat.st_size);
  printf("Opening %s\n", argv[1]);
  char* rom_data = (char*)malloc(rom_size);
  memset(rom_data, 0, rom_size);
  int fd = open(argv[1], O_RDONLY);
  read(fd, rom_data, rom_size);
  close(fd);
  
  size_t search_size = strlen(search_buf);
  size_t i = 0;
  size_t j = 0;
  size_t k = 0;
  int match_valid = 1;

  // 1988 NINTENDO
  //   !! N?N??N
  // Search patterns from rom
  for(i = 0; i < rom_size - search_size; i++)
  {
    match_valid = 1;

    for(j = 0; (j < search_size - 1) && (match_valid); j++)
    {
      // j picks the compare base character from search buffer
      // k picks the character the base is compared to
      // + 1 in initialization because search character always matches itself
      for(k = j + 1; (k < search_size) && (match_valid); k++)
      {
	if((search_buf[j] == search_buf[k]) ==
	   (rom_data[i+j] == rom_data[i+k]))
	{
	  // Character match. If last position, tell address.
	  if((j == search_size - 2) && (k == search_size - 1))
	  {
	    printf("Match at address 0x%X\n", (int)i);
	  }
	}
	else
	{
	  // Character not matched.
	  match_valid = 0;
	}
      }


    }
  }

  free(rom_data);

  return 0;
}
