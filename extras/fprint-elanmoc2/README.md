# Fingerprint reader ELAN 04f3:0c4c on Ubuntu 24.04

Ubuntu's libfprint (1.94.7) does not know this sensor. The community driver `elanmoc2` does (experimental; it is third-party code
that runs inside `fprintd` as root, so read it before you install it). It is built next to Ubuntu's library, nothing under `/usr/lib` is replaced:

    sudo apt install libgusb-dev libnss3-dev
    git clone -b elanmoc2 https://gitlab.freedesktop.org/Depau/libfprint.git ~/build-fprint/libfprint
    cd ~/build-fprint/libfprint
    meson setup build --prefix=/usr/local --libdir=lib/x86_64-linux-gnu -Dintrospection=false -Dgtk-examples=false -Ddoc=false -Dinstalled-tests=false
    ninja -C build
    cp /path/to/this/folder/*.sh ~/build-fprint/ && sudo sh ~/build-fprint/install-driver.sh
    fprintd-list $USER      # should list "ELAN Match-on-Chip 2"
    fprintd-enroll          # teach a finger

`uninstall-driver.sh` goes back to Ubuntu's library. The lock screen uses the reader through `quickshell/pam/fingerprint.conf`.
