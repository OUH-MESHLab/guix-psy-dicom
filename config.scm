;; -*- mode: scheme; -*-
;; This is an operating system configuration for a VM image.
;; Modify it as you see fit and instantiate the changes by running:
;;
;;   guix system reconfigure /etc/config.scm
;;

(use-modules (gnu)
             (guix)
             (guix-systole services dicomd-service)
             (srfi srfi-1))
(use-service-modules desktop mcron networking ssh xorg sddm)
(use-package-modules bootloaders fonts image-processing openbox
                     package-management xdisorg xfce xorg)

(define vm-image-motd (plain-file "motd" "
\x1b[1;37mThis is the GNU system.  Welcome!\x1b[0m

This instance of Guix is a template for virtualized environments.
You can reconfigure the whole system by adjusting /etc/config.scm
and running:

  guix system reconfigure /etc/config.scm

Run '\x1b[1;37minfo guix\x1b[0m' to browse documentation.

\x1b[1;33mConsider setting a password for the 'root' and 'guest' \
accounts.\x1b[0m
"))

(define %dicom-nftables-ruleset
  (plain-file "nftables.conf"
    "
# Default firewall rules
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;

    # Accept established and related connections
    ct state established,related accept

    # Allow loopback traffic
    iifname lo accept

    # Accept ICMP
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept

    # Allow SSH
    tcp dport ssh accept

    # Allow DICOM on port 104 and 1104
    tcp dport { 104, 1104 } accept

    # Reject other traffic
    reject with icmpx type port-unreachable
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
  }
  chain output {
    type filter hook output priority 0; policy accept;
  }
}

# Port redirection from 104 to 1104
table ip nat {
  chain prerouting {
    type nat hook prerouting priority 0; policy accept;
    tcp dport 104 redirect to :1104
  }
  chain output {
    type nat hook output priority 0; policy accept;
    tcp dport 104 redirect to :1104
  }
}
"))


(operating-system
  (host-name "gnu")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))

  ;; Label for the GRUB boot menu.
  (label (string-append "GNU Guix "
                        (or (getenv "GUIX_DISPLAYED_VERSION")
                            (package-version guix))))

  (firmware '())

  ;; Below we assume /dev/vda is the VM's hard disk.
  ;; Adjust as needed.
  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets '("/dev/vda"))
               (terminal-outputs '(console))))
  (file-systems (cons (file-system
                        (mount-point "/")
                        (device "/dev/vda1")
                        (type "ext4"))
                      %base-file-systems))

  (users (cons (user-account
                (name "guest")
                (comment "GNU Guix Live")
                (password "")           ;no password
                (group "users")
                (supplementary-groups '("wheel" "netdev" "dicom"
                                        "audio" "video")))
               %base-user-accounts))

  ;; Our /etc/sudoers file.  Since 'guest' initially has an empty password,
  ;; allow for password-less sudo.
  (sudoers-file (plain-file "sudoers" "\
root ALL=(ALL) ALL
%wheel ALL=NOPASSWD: ALL\n"))

  (packages
   (append (list dcmtk font-bitstream-vera openbox)
           %base-packages))

  (services
   (append (list (service dicomd-service-type
                          (dicomd-configuration
                           (aetitle "PSYDICOM")
                           (output-directory "/var/dicom-store")
                           (log-level "info")))

                 (service slim-service-type
                          (slim-configuration
                           (auto-login? #t)
                           (default-user "guest")
                           (sessreg "openbox")
                           (xorg-configuration
                            (xorg-configuration
                             (keyboard-layout keyboard-layout)))))

                 ;; Uncomment the line below to add an SSH server.
                 ;;(service openssh-service-type)

                 ;; Add the nftables service with the custom ruleset
                 (service nftables-service-type
                          (nftables-configuration
                           (ruleset %dicom-nftables-ruleset)))

                 ;; Use the DHCP client service rather than NetworkManager.
                 (service dhcp-client-service-type))

           ;; Remove some services that don't make sense in a VM.
           (remove (lambda (service)
                     (let ((type (service-kind service)))
                       (or (memq type
                                 (list gdm-service-type
                                       sddm-service-type
                                       wpa-supplicant-service-type
                                       cups-pk-helper-service-type
                                       network-manager-service-type
                                       modem-manager-service-type))
                           (eq? 'network-manager-applet
                                (service-type-name type)))))
                   (modify-services %desktop-services
                     (login-service-type config =>
                                         (login-configuration
                                          (inherit config)
                                          (motd vm-image-motd)))

                     ;; Install and run the current Guix rather than an older
                     ;; snapshot.
                     (guix-service-type config =>
                                        (guix-configuration
                                         (inherit config)
                                         (guix (current-guix))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
