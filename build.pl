#!/usr/bin/env perl
use strict;
use warnings;

my $action = shift // '';

if ($action eq 'build') {
    print "[+] Compiling filesystem packer...\n";
    system("gcc fs.c -o fs_compiler") == 0 or die "[-] Failed to compile fs.c\n";

    print "[+] Generating fs.bin from fs/ directory...\n";
    system("./fs_compiler") == 0 or die "[-] Failed to generate fs.bin\n";

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
    my $fs_size = -s 'fs.bin';

    # Allocate fixed 64 sectors (32768 bytes) for kernel so FS sits safely at 0x30000, in production this should be dynamically calculated.
    my $kernel_target_sectors = 64;
    my $kernel_target_size = $kernel_target_sectors * 512;
    if ($kernel_size > $kernel_target_size) {
        die "[-] Error: Kernel is too large (> $kernel_target_sectors sectors).\n";
    }

    open my $fh, '+<', 'kernel.bin' or die "[-] Cannot open kernel.bin: $!\n";
    binmode($fh);
    seek($fh, 0, 2);
    my $padding = $kernel_target_size - tell($fh);
    print $fh "\x00" x $padding;
    close $fh;

    my $fs_sectors = int(($fs_size + 511) / 512);
    my $total_sectors = $kernel_target_sectors + $fs_sectors;
    print "[+] Kernel size: $kernel_size bytes (Padded to $kernel_target_sectors sectors)\n";
    print "[+] Filesystem size: $fs_size bytes ($fs_sectors sectors)\n";
    print "[+] Total sectors to load: $total_sectors\n";

    open my $boot_fh, '+<', 'boot.bin' or die "[-] Cannot open boot.bin: $!\n";
    binmode($boot_fh);
    local $/;
    my $boot_content = <$boot_fh>;

    my $pos = index($boot_content, "\xb0\x7f");
    if ($pos != -1) {
        seek($boot_fh, $pos + 1, 0);
        print $boot_fh pack('C', $total_sectors);
        print "[+] Patched sector count ($total_sectors) successfully at boot offset $pos\n";
    } else {
        die "[-] Error: Could not find sector count placeholder (\\xb0\\x7f) in boot.bin!\n";
    }
    close $boot_fh;

    sub write_binary_file {
        my ($dest_fh, $filename) = @_;
        open my $src_fh, '<', $filename or die "[-] Cannot open $filename: $!\n";
        binmode($src_fh);
        local $/ = undef;
        my $content = <$src_fh>;
        close $src_fh;
        print $dest_fh $content;
    }

    open my $img_fh, '>', 'os.img' or die "[-] Cannot create os.img: $!\n";
    binmode($img_fh);

    write_binary_file($img_fh, 'boot.bin');
    write_binary_file($img_fh, 'kernel.bin');
    write_binary_file($img_fh, 'fs.bin');

    close $img_fh;
    print "[+] Build complete: os.img created successfully with safe FS placement!\n";

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
