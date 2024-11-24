#!/bin/bash

# WolfOS Build Script
set -e  # Exit on any error

# Configuration
KERNEL_SOURCE="kernel/src/kernel.cpp"
BOOTLOADER="kernel/src/boot/boot.asm"
OUTPUT_DIR="build"
LINKER_SCRIPT="kernel.ld"         # Path to linker script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create build directory
echo -e "${YELLOW}Creating build directory...${NC}"
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}Build directory created at $OUTPUT_DIR${NC}"

echo -e "${YELLOW}Starting WolfOS build process...${NC}"

# Build bootloader
echo -e "${YELLOW}Building bootloader...${NC}"
nasm -f bin "$BOOTLOADER" -o "$OUTPUT_DIR/boot.bin"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build bootloader${NC}"
    exit 1
else
    echo -e "${GREEN}Bootloader successfully built!${NC}"
fi

# Compile kernel
echo -e "${YELLOW}Compiling kernel...${NC}"
g++ -m64 \
    -ffreestanding \
    -fno-exceptions \
    -fno-rtti \
    -mno-red-zone \
    -nostdlib \
    -mcmodel=large \
    -mgeneral-regs-only \
    -Wall \
    -Wextra \
    -O2 \
    -c "$KERNEL_SOURCE" \
    -o "$OUTPUT_DIR/kernel.o"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to compile kernel${NC}"
    exit 1
else
    echo -e "${GREEN}Kernel successfully compiled!${NC}"
fi

# Link kernel
echo -e "${YELLOW}Linking kernel...${NC}"
ld \
    -T "$LINKER_SCRIPT" \
    -o "$OUTPUT_DIR/kernel.bin" \
    "$OUTPUT_DIR/kernel.o"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to link kernel${NC}"
    exit 1
else
    echo -e "${GREEN}Kernel successfully linked!${NC}"
fi

# Create disk image
echo -e "${YELLOW}Creating disk image...${NC}"
# Create a 64MB disk image
dd if=/dev/zero of="$OUTPUT_DIR/wolf_os.img" bs=1M count=64 2>/dev/null
echo -e "${GREEN}Disk image created: $OUTPUT_DIR/wolf_os.img${NC}"

# Write bootloader to first sector
echo -e "${YELLOW}Writing bootloader to disk image...${NC}"
dd if="$OUTPUT_DIR/boot.bin" of="$OUTPUT_DIR/wolf_os.img" conv=notrunc 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to write bootloader to disk image${NC}"
    exit 1
else
    echo -e "${GREEN}Bootloader written successfully!${NC}"
fi

# Write kernel starting from second sector
echo -e "${YELLOW}Writing kernel to disk image...${NC}"
dd if="$OUTPUT_DIR/kernel.bin" of="$OUTPUT_DIR/wolf_os.img" seek=1 conv=notrunc 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to write kernel to disk image${NC}"
    exit 1
else
    echo -e "${GREEN}Kernel written successfully!${NC}"
fi

# Create bootable ISO
echo -e "${YELLOW}Creating bootable ISO...${NC}"
mkdir -p "$OUTPUT_DIR/iso/boot"
cp "$OUTPUT_DIR/wolf_os.img" "$OUTPUT_DIR/iso/boot/"
xorriso -as mkisofs -b boot/wolf_os.img -no-emul-boot -boot-load-size 4 \
        -boot-info-table -o "$OUTPUT_DIR/wolf_os.iso" "$OUTPUT_DIR/iso"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create bootable ISO${NC}"
    exit 1
else
    echo -e "${GREEN}Bootable ISO created successfully!${NC}"
fi

echo -e "${GREEN}Build complete!${NC}"
echo "Output files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"

# Create run script for QEMU
echo -e "${YELLOW}Creating run script for QEMU...${NC}"
cat > run.sh << 'EOF'
#!/bin/bash
qemu-system-x86_64 \
    -drive format=raw,file=build/wolf_os.img \
    -m 128M \
    -cpu qemu64 \
    -nographic \
    -no-reboot \
    -d int,cpu_reset \
    -D qemu.log \
    -serial mon:stdio
EOF

chmod +x run.sh
echo -e "${GREEN}Created run.sh script for QEMU testing${NC}"
echo "To run WolfOS in QEMU, execute: ./run.sh"
