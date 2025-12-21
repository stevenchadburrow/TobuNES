
#./NesGameDev-Composer.o TobuNES-Song.bmp TobuNES-Song.asm ;

./asm6/asm6.o TobuNES-Code.asm TobuNES-ProgramROM.bin ;
./NesGameDev-Converter.o TobuNES-PatternTable0.bmp TobuNES-PatternTable1.bmp TobuNES-CharacterROM.bin ;
./NesGameDev-Combiner.o TobuNES-ProgramROM.bin TobuNES-CharacterROM.bin TOBUNES.NES ;
zip TOBUNES.NES.zip TOBUNES.NES ;

#./Mesen TOBUNES.NES.zip ;
./PICnes.o TOBUNES.NES ;
