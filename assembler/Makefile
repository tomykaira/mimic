include ../Makefile.in

HEADER = ../include/common.h assembler.h

assembler: assembler.o encode.o
assembler.o: $(HEADER) encode.o
encode.o: $(HEADER)

clean:
	$(RM) *.o
	$(RM) assembler

