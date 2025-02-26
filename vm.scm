(use-modules (base)
             (gnu)
             (gnu home)
             (gnu packages gnome)
             (gnu services base)
             (guix)
             (srfi srfi-1))

(use-service-modules desktop mcron spice networking ssh xorg sddm)
(use-package-modules bootloaders fonts
                     package-management xdisorg xorg)

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

  (users (append %psydicom-user-accounts
                 %base-user-accounts))

  ;; Our /etc/sudoers file.  Since 'guest' initially has an empty password,
  ;; allow for password-less sudo.
  (sudoers-file (plain-file "sudoers" "\
root ALL=(ALL) ALL
%wheel ALL=NOPASSWD: ALL\n"))

  (packages
   (append (list 
                 ;; Auto-started script providing SPICE dynamic resizing for
                 ;; Xfce (see:
                 ;; https://gitlab.xfce.org/xfce/xfce4-settings/-/issues/142).
                 xorg-server
                 network-manager
                 x-resize)
           %psydicom-base-packages
           %base-packages))

  (services
   (append (list

                 ;; Add support for the SPICE protocol, which enables dynamic
                 ;; resizing of the guest screen resolution, clipboard
                 ;; integration with the host, etc.
                 (service spice-vdagent-service-type)

                 )

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
                                 (guix (current-guix)))))
           ;; (remove (lambda (service)
           ;;           (let ((type (service-kind service)))
           ;;             (or (memq type
           ;;                       (list s
           ;;                        cups-pk-helper-service-type
           ;;                             modem-manager-service-type))
           ;;                 (eq? 'network-manager-applet
           ;;                      (service-type-name type)))))
           ;;         (modify-services %desktop-services
           ;;           (login-service-type config =>
           ;;                               (login-configuration
           ;;                                (inherit config)
           ;;                                (motd vm-image-motd)))

           ;;           ;; Install and run the current Guix rather than an older
           ;;           ;; snapshot.
           ;;           (guix-service-type config =>
           ;;                              (guix-configuration
           ;;                               (inherit config)
           ;;                               (guix (current-guix))))))
           %psydicom-base-services
           ))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
