#!/bin/sh -e

# A shell script that does the same as the binaries in the release section.

cxxpre=""
gccpre=""
execpre=""
libc6arch="libc6,x86-64"
exec="$APPDIR/usr/bin/$(sed -n -e 's|%f||' -e 's|^Exec=||p' $(ls -1 $APPDIR/*.desktop))"

if [ -n "$APPIMAGE" ] && [ "$(file -b "$APPIMAGE" | cut -d, -f2)" != " x86-64" ]; then
  libc6arch="libc6"
fi

if [ -e "$APPDIR/usr/optional/libstdc++/libstdc++.so.6" ]; then
  lib="$(PATH="/sbin:$PATH" ldconfig -p | grep "libstdc++\.so\.6 ($libc6arch)" | awk 'NR==1{print $NF}')"
  sym_sys=$(tr '\0' '\n' < "$lib" | grep -e '^GLIBCXX_3\.4' | sort -V | tail -n1)
  sym_app=$(tr '\0' '\n' < "$APPDIR/usr/optional/libstdc++/libstdc++.so.6" | grep -e '^GLIBCXX_3\.4' | sort -V | tail -n1)
  if [ "$(printf "${sym_sys}\n${sym_app}"| sort -V | tail -1)" != "$sym_sys" ]; then
    cxxpath="$APPDIR/usr/optional/libstdc++:"
  fi
fi

if [ -e "$APPDIR/usr/optional/libgcc/libgcc_s.so.1" ]; then
  lib="$(PATH="/sbin:$PATH" ldconfig -p | grep "libgcc_s\.so\.1 ($libc6arch)" | awk 'NR==1{print $NF}')"
  sym_sys=$(tr '\0' '\n' < "$lib" | grep -e '^GCC_[0-9]\\.[0-9]' | sort -V | tail -n1)
  sym_app=$(tr '\0' '\n' < "$APPDIR/usr/optional/libgcc/libgcc_s.so.1" | grep -e '^GCC_[0-9]\\.[0-9]' | sort -V | tail -n1)
  if [ "$(printf "${sym_sys}\n${sym_app}"| sort -V | tail -1)" != "$sym_sys" ]; then
    gccpath="$APPDIR/usr/optional/libgcc:"
  fi
fi

if [ -n "$cxxpath" ] || [ -n "$gccpath" ]; then
  if [ -e "$APPDIR/usr/optional/exec.so" ]; then
    execpre=""
    export LD_PRELOAD="$APPDIR/usr/optional/exec.so:${LD_PRELOAD}"
  fi
  export LD_LIBRARY_PATH="${cxxpath}${gccpath}${LD_LIBRARY_PATH}"
fi

# Force xcb platform for Qt applications
if [ -z "${QT_QPA_PLATFORM}" ]; then
    export QT_QPA_PLATFORM=xcb
fi

# Find correct root CA file
_POSSIBLE_CERTIFICATES="/etc/ssl/certs/ca-bundle.crt \
/etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt \
/etc/ssl/ca-bundle.pem /etc/pki/tls/cacert.pem"

if [ -z "$SSL_CERT_FILE" ]; then
    for i in $_POSSIBLE_CERTIFICATES; do 
        if [ -f "$i" ]; then
            export SSL_CERT_FILE="$i"
            break
        fi
    done
fi

#echo ">>>>> $LD_LIBRARY_PATH"
#echo ">>>>> $LD_PRELOAD"

exec $exec "$@"

