TARGET = i386-unknown-none

BUILD_DIR = build
BOOT_DIR = boot
ISODIR = $(BUILD_DIR)/isofiles
RUST_SRCS = $(wildcard src/*.rs)
RUST_SRCS += Cargo.toml

KERNEL_BIN = $(BUILD_DIR)/kernel.bin
ISO = kfs.iso
RUST_LIB = target/$(TARGET)/release/libkfs.a

NASM = nasm
CARGO = cargo
LD = ld
QEMU = qemu-system-i386
DOCKER = docker

all: $(ISO)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	mkdir -p $(ISODIR)/boot/grub

$(BUILD_DIR)/boot.o: $(BOOT_DIR)/boot.asm | $(BUILD_DIR)
	$(NASM) -f elf32 -o $@ $<

$(RUST_LIB): $(RUST_SRCS)
	$(CARGO) build -r

$(KERNEL_BIN): $(BUILD_DIR)/boot.o $(RUST_LIB) linker.ld
	$(LD) -m elf_i386 -n -o $@ -T linker.ld $(BUILD_DIR)/boot.o $(RUST_LIB)

$(ISO): $(KERNEL_BIN) $(BOOT_DIR)/grub.cfg | $(BUILD_DIR)
	cp $(KERNEL_BIN) $(ISODIR)/boot/kernel.bin
	cp $(BOOT_DIR)/grub.cfg $(ISODIR)/boot/grub/
	grub-mkrescue -o $@ $(ISODIR)

run: $(ISO)
	$(QEMU) -cdrom $(ISO)

debug: $(ISO)
	$(QEMU) -cdrom $(ISO) -s -S

docker:
	$(DOCKER) build --platform linux/amd64 --tag kfs-build .
	$(DOCKER) run --rm -v .:/kfs kfs-build

clean:
	$(CARGO) clean
	rm -rf $(BUILD_DIR)
	rm -f $(ISO)

re: clean all

.PHONY: all run debug clean re
