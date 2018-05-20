ifndef cross_compile
cross_compile = mips-sde-elf-
endif

AS = $(cross_compile)as
LD = $(cross_compile)ld
OBJCOPY = $(cross_compile)objcopy
OBJDUMP = $(cross_compile)objdump

vpath %.s ../data

targets = $(patsubst %.s,%.txt,$(wildcard ../data/*.s))


# compile rules

.PHONY: all compile
all: bin2mem compile

bin2mem: bin2mem.cpp
	g++ -o bin2mem bin2mem.cpp

compile: $(targets)


%.o: %.s
	$(AS) -mips32 $< -o $@

%.om: %.o ram.ld
	$(LD) -T ram.ld $< -o $@

%.bin: %.om
	$(OBJCOPY) -O binary $< $@

%.txt: %.bin
	./bin2mem -o $@ $<

clean:
	rm -f ../data/*.txt