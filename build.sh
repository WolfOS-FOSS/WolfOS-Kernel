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
    -T ./kernel.ld \
    -c "$KERNEL_SOURCE" \
    -o "kernel/src/boot/kernel.efi"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to compile kernel${NC}"
    exit 1
else
    echo -e "${GREEN}Kernel successfully compiled!${NC}"
fi


# Build bootloader
echo -e "${YELLOW}Building bootloader...${NC}"
INPUT="kernel/src/boot/boot.asm"
OUTPUT="build/final.img"
KERN="kernel/src/boot/kernel.efi"

# Get the size of the kernel file using wc -c (in bytes)
K_SZ=$(wc -c < $KERN)

# padding to make it up to a 512-byte boundary for the kernel
K_PAD=$((512 - K_SZ % 512))

# Get the size of the initial RAM disk, if any (e.g., 0 if none)
R_SZ=0  # You can calculate this if you have an initrd (change as needed)

# Calculate the total size we need for the image to be exactly 8MB
TOTAL_SIZE=8388608  # 8MB in bytes

# Current image size (kernel + padding + initrd)
CURRENT_SIZE=$((K_SZ + R_SZ + K_PAD))

# Calculate how much more padding is required
REQUIRED_PADDING=$((TOTAL_SIZE - CURRENT_SIZE))

# Make sure we're not padding too little
if [[ $REQUIRED_PADDING -gt 0 ]]; then
    PADDING_SIZE=$REQUIRED_PADDING
else
    PADDING_SIZE=0
fi

# Assemble the bootloader image
nasm -o $OUTPUT -D initRdSizeDef=$R_SZ $INPUT
cat $KERN >> $OUTPUT
if [[ $K_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$K_PAD >> $OUTPUT
fi

# Add additional padding to make the image exactly 8MB
if [[ $PADDING_SIZE -gt 0 ]]; then
    dd if=/dev/zero bs=1 count=$PADDING_SIZE >> $OUTPUT
fi

echo -e "${GREEN}Bootloader built successfully!${NC}"



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
dd if="$OUTPUT_DIR/kernel.efi" of="$OUTPUT_DIR/wolf_os.img" seek=1 conv=notrunc 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to write kernel to disk image${NC}"
    exit 1
else
    echo -e "${GREEN}Kernel written successfully!${NC}"
fi

# Create bootable ISO
echo -e "${BLUE}Creating bootable ISO...${NC}"
xorriso -as mkisofs -b build/wolf_os.img -no-emul-boot -boot-load-size 4 \
        -boot-info-table -o "iso/wolf_os.iso""
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
