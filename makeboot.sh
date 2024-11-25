KERNEL_SOURCE="kernel/src/kernel.cpp"
BOOTLOADER="kernel/src/boot/boot.asm"
OUTPUT_DIR="build"
LINKER_SCRIPT="kernel.ld"         # Path to linker script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Build bootloader
echo -e "${YELLOW}Building bootloader...${NC}"
INPUT="kernel/src/boot/boot.asm"
OUTPUT="build/final.img"
KERN="kernel/src/boot/kernel.bin"


K_SZ=`stat -c %s $KERN`

#padding to make it up to a sector
K_PAD=$((512 - $K_SZ % 512))

nasm -o $OUTPUT -D initRdSizeDef=$R_SZ $INPUT
cat $KERN >> $OUTPUT
if [[ $K_PAD -lt 512 ]]; then
    dd if=/dev/zero bs=1 count=$K_PAD >> $OUTPUT
fi

TOTAL=`stat -c %s $OUTPUT`
echo "concatenated bootloader, and kernel into ::> $OUTPUT"
