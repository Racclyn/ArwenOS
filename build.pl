#!/usr/bin/env perl
use strict;
use warnings;

my $action = shift // '';

if ($action eq 'build') {
    print "[+] Compiling kernel entry...\n";
    system("nasm -f elf32 kstart.o kstart.asm 2>/dev/null || nasm -f elf32 kstart.asm -o kstart.o") == 0 or die "[-] Failed to compile kernel entry\n";

    print "[+] Compiling C kernel...\n";
    system("gcc -m32 -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -c kernel.c -o kernel.o") == 0 or die "[-] Failed to compile C kernel\n";

    print "[+] Linking kernel as ELF...\n";
    system("ld -m elf_i386 -T linker.ld kstart.o kernel.o -o kernel.tmp") == 0 or die "[-] Failed to link kernel ELF\n";

    print "[+] Extracting raw binary with objcopy...\n";
    system("objcopy -O binary kernel.tmp kernel.bin") == 0 or die "[-] Failed to extract binary\n";

    print "[+] Assembling bootloader...\n";
    system("nasm -f bin boot.asm -o boot.bin") == 0 or die "[-] Failed to assemble bootloader\n";

    my $kernel_size = -s 'kernel.bin';
    my $sectors = int(($kernel_size + 511) / 512);
    print "[+] Kernel size: $kernel_size bytes ($sectors sectors)\n";

    my $target_size = $sectors * 512;
    open my $fh, '+<', 'kernel.bin' or die "[-] Cannot open kernel.bin: $!\n";
    binmode($fh);
    seek($fh, 0, 2);
    my $padding = $target_size - tell($fh);
    print $fh "\x00" x $padding;
    close $fh;

    print "[+] Padded kernel to exact size: $sectors sectors ($target_size bytes)\n";

    open my $boot_fh, '+<', 'boot.bin' or die "[-] Cannot open boot.bin: $!\n";
    binmode($boot_fh);
    local $/;
    my $boot_content = <$boot_fh>;

    my $pos = index($boot_content, "\xb0\x7f");
    if ($pos != -1) {
        seek($boot_fh, $pos + 1, 0);
        print $boot_fh pack('C', $sectors);
        print "[+] Patched sector count ($sectors) successfully at boot offset $pos\n";
    } else {
        die "[-] Error: Could not find sector count placeholder (\\xb0\\x7f) in boot.bin!\n";
    }
    close $boot_fh;

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
    system("qemu-system-x86_64 -drive format=raw,file=os.img -no-reboot");

} else {
    print "Usage: ./build.pl [build|run]\n";
    exit 1;
}
