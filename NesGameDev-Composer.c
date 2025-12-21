// NesGameDev-Composer.c

// Converts a 1024x64 BMP file into hex-values for a song.

#include <stdio.h>
#include <stdlib.h>

unsigned int bitmap_red[1024][64];
unsigned int bitmap_green[1024][64];
unsigned int bitmap_blue[1024][64];

unsigned char hex_stream1[1024*2];
unsigned char hex_stream2[1024*2];
unsigned char hex_stream3[1024*2];

// start at C-9 going down to E-2, zero at end
const unsigned char note_conversion[48] = {
	120, 119, 117, 155, 113, 112, 110, 
	108, 107, 105, 103, 101, 100,  98,  
	 96,  95,  93,  91,  89,  88,  86,  
	 84,  83,  81,  79,  77,  76,  74,  
	 72,  71,  69,  67,  65,  64,  62, 
	 60,  59,  57,  55,  53,  52,  50,  
	 48,  57,  45,  43,  41,  40
};

int main(const int argc, const char **argv)
{
	if (argc < 3)
	{
		printf("Arguments: <input.bmp> <output.hex>\n");
		return 0;
	}

	FILE *input = NULL;

	input = fopen(argv[1], "rb");
	if (!input)
	{
		printf("Could not open %s\n", argv[1]);
		return 0;
	}

	unsigned char buffer;
	unsigned char red, green, blue;

	for (int i=0; i<54; i++) fscanf(input, "%c", &buffer); // header

	for (int y=63; y>=0; y--) // from bottom-left corner
	{
		for (int x=0; x<1024; x++)
		{
			fscanf(input, "%c%c%c", &blue, &green, &red); // bgr format

			bitmap_red[x][y] = red;
			bitmap_green[x][y] = green;
			bitmap_blue[x][y] = blue;
		}
	}

	fclose(input);

	unsigned long pos = 0;
	unsigned char curr_val = 0;
	unsigned char prev_val = 0;
	unsigned char prev_cnt = 1;
	unsigned char quit = 0;

	for (int x=0; x<1024; x++)
	{
		curr_val = 0; // silence

		for (int y=0; y<47; y++)
		{
			if (bitmap_red[x][y] > 0x00 && 
				bitmap_green[x][y] > 0x00 && 
				bitmap_blue[x][y] > 0x00)
			{
				quit = 1;

				break;
			}

			if (bitmap_red[x][y] > 0x00)
			{
				if (note_conversion[y] > 0)
				{
					curr_val = note_conversion[y];
				}

				break;
			}
		}

		if (quit == 1)
		{
			hex_stream1[pos] = prev_val;
			hex_stream1[pos+1] = prev_cnt;
			
			for (int i=pos+2; i<1024*2; i++)
			{
				hex_stream1[i] = 0xFF;
			}
			
			break;
		}
		else if (curr_val == prev_val)
		{
			prev_cnt++;
	
			if (prev_cnt >= 0xC0)
			{
				hex_stream1[pos] = prev_val;
				hex_stream1[pos+1] = prev_cnt;

				prev_val = curr_val;
				prev_cnt = 1;

				pos += 2;
			}
		}
		else
		{
			hex_stream1[pos] = prev_val;
			hex_stream1[pos+1] = prev_cnt;

			prev_val = curr_val;
			prev_cnt = 1;

			pos += 2;
		}
	}

	if (quit == 0)
	{
		hex_stream1[pos] = prev_val;
		hex_stream1[pos+1] = prev_cnt;
	}

	pos = 0;
	curr_val = 0;
	prev_val = 0;
	prev_cnt = 1;
	quit = 0;

	for (int x=0; x<1024; x++)
	{
		curr_val = 0; // silence

		for (int y=0; y<47; y++)
		{
			if (bitmap_red[x][y] > 0x00 && 
				bitmap_green[x][y] > 0x00 && 
				bitmap_blue[x][y] > 0x00)
			{
				quit = 1;

				break;
			}

			if (bitmap_green[x][y] > 0x00)
			{
				if (note_conversion[y] > 0)
				{
					curr_val = note_conversion[y];
				}

				break;
			}
		}

		if (quit == 1)
		{
			hex_stream2[pos] = prev_val;
			hex_stream2[pos+1] = prev_cnt;
			
			for (int i=pos+2; i<1024*2; i++)
			{
				hex_stream2[i] = 0xFF;
			}
			
			break;
		}
		else if (curr_val == prev_val)
		{
			prev_cnt++;

			if (prev_cnt >= 0xC0)
			{
				hex_stream2[pos] = prev_val;
				hex_stream2[pos+1] = prev_cnt;

				prev_val = curr_val;
				prev_cnt = 1;

				pos += 2;
			}
		}
		else
		{
			hex_stream2[pos] = prev_val;
			hex_stream2[pos+1] = prev_cnt;

			prev_val = curr_val;
			prev_cnt = 1;

			pos += 2;
		}
	}

	if (quit == 0)
	{
		hex_stream2[pos] = prev_val;
		hex_stream2[pos+1] = prev_cnt;
	}

	pos = 0;
	curr_val = 15;
	prev_val = 15;
	prev_cnt = 1;
	quit = 0;

	for (int x=0; x<1024; x++)
	{
		curr_val = 15; // silence

		for (int y=48; y<64; y++)
		{
			if (bitmap_red[x][y] > 0x00 && 
				bitmap_green[x][y] > 0x00 && 
				bitmap_blue[x][y] > 0x00)
			{
				quit = 1;

				break;
			}

			if (bitmap_blue[x][y] > 0x00)
			{
				curr_val = y - 48;

				break;
			}
		}

		if (quit == 1)
		{
			hex_stream3[pos] = prev_val;
			hex_stream3[pos+1] = prev_cnt;
			
			for (int i=pos+2; i<1024*2; i++)
			{
				hex_stream3[i] = 0xFF;
			}
			
			break;
		}
		else if (curr_val == prev_val)
		{
			prev_cnt++;

			if (prev_cnt >= 0xC0)
			{
				hex_stream3[pos] = prev_val;
				hex_stream3[pos+1] = prev_cnt;

				prev_val = curr_val;
				prev_cnt = 1;

				pos += 2;
			}
		}
		else
		{
			hex_stream3[pos] = prev_val;
			hex_stream3[pos+1] = prev_cnt;

			prev_val = curr_val;
			prev_cnt = 1;

			pos += 2;
		}
	}

	if (quit == 0)
	{
		hex_stream3[pos] = prev_val;
		hex_stream3[pos+1] = prev_cnt;
	}

	FILE *output = NULL;

	output = fopen(argv[2], "wt");
	if (!output)
	{
		printf("Could not open %s\n", argv[2]);
		return 0;
	}

	fprintf(output, "audio_pulse2_data\n");

	for (int x=0; x<1024*2; x+=8)
	{
		fprintf(output, "\t.BYTE ");

		for (int i=0; i<8; i++)
		{
			fprintf(output, "$%02X", hex_stream1[x+i]);
		
			if (i < 7) fprintf(output, ",");
		}

		fprintf(output, "\n");
	}

	fprintf(output, "\n");

	fprintf(output, "audio_triangle_data\n");

	for (int x=0; x<1024*2; x+=8)
	{
		fprintf(output, "\t.BYTE ");

		for (int i=0; i<8; i++)
		{
			fprintf(output, "$%02X", hex_stream2[x+i]);
		
			if (i < 7) fprintf(output, ",");
		}

		fprintf(output, "\n");
	}

	fprintf(output, "\n");

	fprintf(output, "audio_noise_data\n");

	for (int x=0; x<1024*2; x+=8)
	{
		fprintf(output, "\t.BYTE ");

		for (int i=0; i<8; i++)
		{
			fprintf(output, "$%02X", hex_stream3[x+i]);
		
			if (i < 7) fprintf(output, ",");
		}

		fprintf(output, "\n");
	}

	fprintf(output, "\n");

	fclose(output);

	return 1;
}
