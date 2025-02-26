(use-modules (gnu)
             (gnu home)
             (gnu home services)
             (gnu packages certs)
             (gnu packages vim)
             (gnu packages gnome)
             (gnu packages gnuzilla)
             (gnu services guix)
             (guix-systole services dicomd-service)
             (guix-systole packages wallpapers)
             (guix-systole artwork))

(use-service-modules cups desktop networking ssh xorg sddm)

(use-package-modules bootloaders fonts openbox xfce lxde image-processing
                     kde-frameworks package-management xdisorg xorg wm conky
                     image-viewers linux disk)

(define conkyrc
  (local-file "etc/conky/conky.conf"))

(define fluxbox-init
  (local-file "etc/fluxbox/init"))

(define fluxbox-keys
  (local-file "etc/fluxbox/keys"))

(define fluxbox-menu
  (local-file "etc/fluxbox/menu"))

(define fluxbox-startup
  (local-file "etc/fluxbox/startup"))

(define ideskrc
  (local-file "etc/idesk/ideskrc"))

(define idesk-icon-lnk
  (local-file "etc/idesk/DICOMStore.lnk"))

(define nftables-config
  (local-file "etc/misc/nftables.conf"))

(define guest-home
  (home-environment
    (services
     (cons*
      (service
       home-xdg-configuration-files-service-type
       `())
      (service
       home-files-service-type
       `((".fluxbox/init" ,fluxbox-init)
         (".fluxbox/keys" ,fluxbox-keys)
         (".fluxbox/startup" ,fluxbox-startup)
         (".idesktop/DICOMStore.lnk" ,idesk-icon-lnk)
         (".conkyrc" ,conkyrc)
         (".ideskrc" ,ideskrc)
         ))
      %base-home-services))))


(define psydicom-os

  (operating-system
    (locale "en_US.utf8")
    (timezone "Europe/Oslo")
    (keyboard-layout (keyboard-layout "us" "altgr-intl"))
    (host-name "PSYDICOM")

    (initrd-modules (cons* "raid1"  %base-initrd-modules))

    ;; The list of user accounts ('root' is implicit).
    (users (append (list  (user-account
                           (name "admin")
                           (comment "Admin")
                           (group "users")
                           (home-directory "/home/admin")
                           (supplementary-groups '("wheel" "netdev" "audio" "video")))
                          (user-account
                           (name "guest")
                           (comment "PSYDICOM Guest user")
                           (password "")           ;no password
                           (group "users")
                           (supplementary-groups '("wheel" "netdev" "dicom"
                                                   "audio" "video"))))
                   %base-user-accounts))
    (sudoers-file
     (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                (format #f "~a ALL = NOPASSWD: ALL~%"
                                        "admin"))))

    (mapped-devices
     (list (mapped-device
            (source (list "/dev/sda1" "/dev/sdb1"))
            (target "/dev/md127")
            (type raid-device-mapping))))

    (packages (append (list
                       conky
                            dcmtk
                            feh
                            fluxbox
                            font-bitstream-vera
                            font-dejavu
                            idesk
                            mdadm
                            ntfs-3g
                            oxygen-icons
                            parted
                            gparted
                            systole-wallpapers
                            thunar
                            xfce4-terminal
                            vim
                            gvfs)
                      %base-packages))

    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (services
     (append (list

              (service openssh-service-type)

                   ;; (set-xorg-configuration
                   ;;  (xorg-configuration (keyboard-layout keyboard-layout)))

                   (service nftables-service-type
                            (nftables-configuration
                             (ruleset (local-file "etc/nftables.conf"))))

                   (service dicomd-service-type
                            (dicomd-configuration
                             (aetitle "PSYDICOM")
                             (output-directory "/var/dicom-store")))

                   (service guix-home-service-type
                            `(("guest" ,guest-home))))

             (modify-services %desktop-services
               ;;https://issues.guix.gnu.org/46760
               (guix-service-type config =>
                                  (guix-configuration
                                   (authorized-keys (append `(,(local-file
                                                                "/etc/guix/signing-key.pub")) %default-authorized-guix-keys)))))))

    (bootloader (bootloader-configuration
                 (bootloader grub-bootloader)
                 (targets (list "/dev/nvme0n1"))
                 (keyboard-layout keyboard-layout)))
    (swap-devices (list (swap-space
                          (target "/dev/nvme0n1p2"))))

    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (file-systems (cons* (file-system
                           (mount-point "/")
                           (device "/dev/nvme0n1p3")
                           (type "ext4"))

                         (file-system
                           (mount-point "/var/dicom-store")
                           (device "/dev/md127")
                           ;; (flags '(no-suid no-dev no-exec))
                           ;; (options (alist->file-system-options '("defaults"
                           ;;                                        ("uid" . "1030")
                           ;;                                        ("gid" . "1031"))))
                           (mount? #t)
                           (type "ext4")
                           (dependencies mapped-devices))

                         %base-file-systems))))

(list (machine
       (operating-system psydicom-os)
       (environment managed-host-environment-type)
       (configuration (machine-ssh-configuration
                       (host-name "10.160.140.254")
                       (system "x86_64-linux")
                       (user "admin")
                       (identity "./id_rsa")
                       (port 22)))))
