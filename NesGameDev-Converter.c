// converts two 128x128 .bmp files to one chr-rom .bin file

#include <stdio.h>
#include <stdlib.h>

unsigned char pixel_red[128][128];
unsigned char pixel_cyan[128][128];

int main(const int argc, const char **argv)
{
	if (argc < 4)
	{
		printf("Arguments: <PatternTable0.bmp> <PatternTable1.bmp> <Output.bin>\n");
		return 0;
	}

	unsigned char buffer = 0;

	unsigned char red, green, blue;

	unsigned char left[8], right[8];

	FILE *output = NULL;

	output = fopen(argv[3], "wb");
	if (!output)
	{
		printf("Could not open %s\n", argv[3]);
	}

	// read first pattern table
	
	FILE *input = NULL;
	
	input = fopen(argv[1], "rb");
	if (!input)
	{
		printf("Could not open %s\n", argv[1]);
		return 0;
	}

	for (int i=0; i<54; i++) fscanf(input, "%c", &buffer); // header

	for (int y=128-1; y>=0; y--) // from bottom-left corner
	{
		for (int x=0; x<128; x++)
		{
			fscanf(input, "%c%c%c", &blue, &green, &red); // bgr format
		
			if (red >= 0xC0 && green >= 0xC0 && blue >= 0xC0) // white
			{
				pixel_red[x][y] = 1;
				pixel_cyan[x][y] = 1;
			}
			else if (red >= 0xC0 && green < 0xC0 && blue < 0xC0) // red
			{
				pixel_red[x][y] = 1;
				pixel_cyan[x][y] = 0;
			}
			else if (red < 0xC0 && (green >= 0xC0 && blue >= 0xC0)) // cyan
			{
				pixel_red[x][y] = 0;
				pixel_cyan[x][y] = 1;
			}
			else // black
			{
				pixel_red[x][y] = 0;
				pixel_cyan[x][y] = 0;
			}
		}
	}

	for (int y=0; y<128/8; y++)
	{
		for (int x=0; x<128; x+=8)
		{
			for (int i=0; i<8; i++)
			{
				left[i] = (pixel_red[x+0][y*8+i] << 7) |
					(pixel_red[x+1][y*8+i] << 6) |
					(pixel_red[x+2][y*8+i] << 5) |
					(pixel_red[x+3][y*8+i] << 4) |
					(pixel_red[x+4][y*8+i] << 3) |
					(pixel_red[x+5][y*8+i] << 2) |
					(pixel_red[x+6][y*8+i] << 1) |
					(pixel_red[x+7][y*8+i]);
				
				right[i] = (pixel_cyan[x+0][y*8+i] << 7) |
					(pixel_cyan[x+1][y*8+i] << 6) |
					(pixel_cyan[x+2][y*8+i] << 5) |
					(pixel_cyan[x+3][y*8+i] << 4) |
					(pixel_cyan[x+4][y*8+i] << 3) |
					(pixel_cyan[x+5][y*8+i] << 2) |
					(pixel_cyan[x+6][y*8+i] << 1) |
					(pixel_cyan[x+7][y*8+i]);
			}

			fprintf(output, "%c%c%c%c%c%c%c%c",
				left[0], left[1], left[2], left[3],
				left[4], left[5], left[6], left[7]);

			fprintf(output, "%c%c%c%c%c%c%c%c",
				right[0], right[1], right[2], right[3],
				right[4], right[5], right[6], right[7]);
		}
	}

	fclose(input);

	// read second pattern table

	input = NULL;

	input = fopen(argv[2], "rb");
	if (!input)
	{
		printf("Could not open %s\n", argv[2]);
		return 0;
	}

	for (int i=0; i<54; i++) fscanf(input, "%c", &buffer); // header

	for (int y=128-1; y>=0; y--) // from bottom-left corner
	{
		for (int x=0; x<128; x++)
		{
			fscanf(input, "%c%c%c", &blue, &green, &red); // bgr format
		
			if (red >= 0xC0 && green >= 0xC0 && blue >= 0xC0) // white
			{
				pixel_red[x][y] = 1;
				pixel_cyan[x][y] = 1;
			}
			else if (red >= 0xC0 && green < 0xC0 && blue < 0xC0) // red
			{
				pixel_red[x][y] = 1;
				pixel_cyan[x][y] = 0;
			}
			else if (red < 0xC0 && (green >= 0xC0 && blue >= 0xC0)) // cyan
			{
				pixel_red[x][y] = 0;
				pixel_cyan[x][y] = 1;
			}
			else // black
			{
				pixel_red[x][y] = 0;
				pixel_cyan[x][y] = 0;
			}
		}
	}

	for (int y=0; y<128/8; y++)
	{
		for (int x=0; x<128; x+=8)
		{
			for (int i=0; i<8; i++)
			{
				left[i] = (pixel_red[x+0][y*8+i] << 7) |
					(pixel_red[x+1][y*8+i] << 6) |
					(pixel_red[x+2][y*8+i] << 5) |
					(pixel_red[x+3][y*8+i] << 4) |
					(pixel_red[x+4][y*8+i] << 3) |
					(pixel_red[x+5][y*8+i] << 2) |
					(pixel_red[x+6][y*8+i] << 1) |
					(pixel_red[x+7][y*8+i]);
				
				right[i] = (pixel_cyan[x+0][y*8+i] << 7) |
					(pixel_cyan[x+1][y*8+i] << 6) |
					(pixel_cyan[x+2][y*8+i] << 5) |
					(pixel_cyan[x+3][y*8+i] << 4) |
					(pixel_cyan[x+4][y*8+i] << 3) |
					(pixel_cyan[x+5][y*8+i] << 2) |
					(pixel_cyan[x+6][y*8+i] << 1) |
					(pixel_cyan[x+7][y*8+i]);
			}

			fprintf(output, "%c%c%c%c%c%c%c%c",
				left[0], left[1], left[2], left[3],
				left[4], left[5], left[6], left[7]);

			fprintf(output, "%c%c%c%c%c%c%c%c",
				right[0], right[1], right[2], right[3],
				right[4], right[5], right[6], right[7]);
		}
	}

	fclose(input);

	fclose(output);

	return 1;
}
