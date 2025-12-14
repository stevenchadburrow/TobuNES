#include <stdio.h>
#include <stdlib.h>

unsigned char header[16] = {
	0x4e, 0x45, 0x53, 0x1a, 0x02, 0x01, 0x00, 0x08, 
	0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x01
};

int main(const int argc, const char **argv)
{
	if (argc < 4)
	{
		printf("Arguments: <PRG-ROM.BIN> <CHR-ROM.BIN> <OUTPUT.NES>\n");
		
		return 0;
	}

	FILE *prg_rom = NULL;

	prg_rom = fopen(argv[1], "rb");
	if (!prg_rom)
	{
		printf("Error opening %s\n", argv[1]);

		return 0;
	}

	FILE *chr_rom = NULL;

	chr_rom = fopen(argv[2], "rt");
	if (!chr_rom)
	{
		printf("Error opening %s\n", argv[2]);
	}

	FILE *output = NULL;

	output = fopen(argv[3], "wt");
	if (!output)
	{
		printf("Error opening %s\n", argv[3]);
		return 0;
	}
	
	// HEADER

	for (int i=0; i<16; i++)
	{
		fprintf(output, "%c", header[i]);
	}

	// PRG-ROM

	unsigned char buffer = 0;

	for (int i=0; i<32768; i++)
	{
		fscanf(prg_rom, "%c", &buffer);

		fprintf(output, "%c", buffer);
	}

	// CHR-ROM

	for (int i=0; i<8192; i++)
	{
		fscanf(chr_rom, "%c", &buffer);

		fprintf(output, "%c", buffer);
	}

	fclose(prg_rom);
	fclose(chr_rom);
	fclose(output);

	return 1;
}
