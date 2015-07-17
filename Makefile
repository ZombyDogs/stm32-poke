CC=arm-none-eabi-

TARGET_CFLAGS = -mcpu=cortex-m3 -mthumb
COMMON_CFLAGS = $(TARGET_CFLAGS) -Ilib
COMMON_LDFLAGS = -Llib

PROGRAMS = \
    blink       \
    pwm_blink   \
    usart_hello

.PHONY: lib clean

all: $(PROGRAMS:=.bin)

lib:
	$(MAKE) -Clib

%.o: %.c
	$(CC)gcc $(COMMON_CFLAGS) $(CFLAGS) -c -o $@ $<
	$(CC)gcc $(COMMON_CFLAGS) $(CFLAGS) -MM $< > $*.d

%.o: %.S
	$(CC)gcc $(COMMON_CFLAGS) $(CFLAGS) -D__ASSEMBLY__ -c -o $@ $<
	$(CC)gcc $(COMMON_CFLAGS) $(CFLAGS) -D__ASSEMBLY__ -MM $< > $*.d

define ELF_RULE
$(strip $(1))_OBJS = $(1)_vectors.o \
                     $$(addsuffix .o, $(1) $$($(strip $(1))_MODULES))
$(1).elf: $$($(strip $(1))_OBJS) flash.ld memory.ld lib
	$(CC)ld -T flash.ld $(COMMON_LDFLAGS) -o $$@ \
		$$($(strip $(1))_OBJS) -lstammer
OBJS += $$($(strip $(1))_OBJS)
endef
$(foreach p, $(PROGRAMS), $(eval $(call ELF_RULE, $(p))))
DEPS = $(OBJS:.o=.d)
-include $(DEPS)

%.bin: %.elf
	$(CC)objcopy -O binary $< $@

clean:
	$(MAKE) -Clib clean
	rm -f $(OBJS)
	rm -f $(DEPS)
	rm -f $(PROGRAMS:=.elf)
	rm -f $(PROGRAMS:=.bin)
