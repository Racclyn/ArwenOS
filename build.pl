#!/usr/bin/env perl
use strict;
use warnings;

my $action = shift // '';

if ($action eq 'build') {
    print "[+] Compiling kernel entry...\n";
    system("nasm -f elf32 kstart.asm -o kstart.o") == 0 or die "[-] Failed to compile kernel entry\n";

    print "[+] Compiling C kernel...\n";
    system("gcc -m16 -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -c kernel.c -o kernel.o") == 0 or die "[-] Failed to compile C kernel\n";

    print "[+] Linking kernel with linker script...\n";
    system("ld -m elf_i386 -T linker.ld kstart.o kernel.o -o kernel.bin") == 0 or die "[-] Failed to link kernel\n";

    print "[+] Assembling bootloader...\n";
    system("nasm -f bin boot.asm -o boot.bin") == 0 or die "[-] Failed to assemble bootloader\n";

    my $kernel_size = -s 'kernel.bin';
    my $sectors = int(($kernel_size + 511) / 512);
    print "[+] Kernel size: $kernel_size bytes ($sectors sectors)\n";

    if ($sectors > 127) {
        die "[-] Error: Kernel is too large (>127 sectors).\n";
    }

    # Pad kernel.bin to a multiple of 512 bytes
    open my $fh, '+<', 'kernel.bin' or die "[-] Cannot open kernel.bin: $!\n";
    binmode($fh);
    seek($fh, 0, 2); # Seek to end
    my $size = tell($fh);
    my $padding = (512 - ($size % 512)) % 512;
    print $fh "\x00" x $padding;
    close $fh;

    # Recalculate sectors after padding
    $kernel_size = -s 'kernel.bin';
    $sectors = int($kernel_size / 512);

    # Patch boot.bin with sector count
    open my $boot_fh, '+<', 'boot.bin' or die "[-] Cannot open boot.bin: $!\n";
    binmode($boot_fh);
    local $/;
    my $content = <$boot_fh>;
    my $pos = index($content, "\x05");

    if ($pos != -1) {
        seek($boot_fh, $pos, 0);
        print $boot_fh pack('C', $sectors);
        print "[+] Patched sector count ($sectors) at offset $pos\n";
    } else {
        print "[-] Warning: Could not auto-patch sector count placeholder!\n";
    }
    close $boot_fh;

    # Combine boot.bin and kernel.bin into os.img
    open my $img_fh, '>', 'os.img' or die "[-] Cannot create os.img: $!\n";
    binmode($img_fh);

    open my $b_fh, '<', 'boot.bin' or die "[-] Cannot open boot.bin: $!\n";
    binmode($b_fh);
    print $img_fh $_ while (<$b_fh>);
    close $b_fh;

    open my $k_fh, '<', 'kernel.bin' or die "[-] Cannot open kernel.bin: $!\n";
    binmode($k_fh);
    print $img_fh $_ while (<$k_fh>);
    close $k_fh;

    close $img_fh;
    print "[+] Build complete: os.img created successfully!\n";

} elsif ($action eq 'run') {
    if (!-f 'os.img') {
        die "[-] os.img not found! Run './build.pl build' first.\n";
    }
    print "[+] Launching QEMU...\n";
    system("qemu-system-x86_64 -drive format=raw,file=os.img");

} else {
    print "Usage: ./build.pl [build|run]\n";
    exit 1;
}
