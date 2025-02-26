;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
             (gnu packages vim)
             (gnu packages package-management)
             (gnu packages version-control)
             (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop mcron networking spice ssh xorg sddm desktop dbus)
(use-package-modules bootloaders fonts openbox xfce lxde image-processing
                     kde-frameworks package-management xdisorg xorg wm conky
                     image-viewers polkit gnome freedesktop xfce gtk linux)

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


(operating-system
 (locale "en_US.utf8")
 (timezone "Europe/Oslo")
 (keyboard-layout (keyboard-layout "us"))
 (host-name "p3600")

  ;; Label for the GRUB boot menu.
  (label (string-append "GNU Guix "
                        (or (getenv "GUIX_DISPLAYED_VERSION")
                            (package-version guix))))

 (kernel linux)
 (initrd microcode-initrd)
 (firmware (list linux-firmware))

 ;; The list of user accounts ('root' is implicit).
 (users (cons* (user-account
                (name "rafael")
                (comment "Rafael Palomar")
                (group "users")
                (home-directory "/home/rafael")
                (supplementary-groups '("wheel" "netdev" "audio" "video" "dicom")))
               %base-user-accounts))

  ;; Our /etc/sudoers file.  Since 'guest' initially has an empty password,
  ;; allow for password-less sudo.
  (sudoers-file (plain-file "sudoers" "\
root ALL=(ALL) ALL
%wheel ALL=NOPASSWD: ALL\n"))

 ;; Packages installed system-wide.  Users can also install packages
 ;; under their own account: use 'guix search KEYWORD' to search
 ;; for packages and 'guix install PACKAGE' to install a package.
 (packages (append (list vim
			             flatpak
                         at-spi2-core
                         conky
                         dcmtk
                         feh
                         fluxbox
                         font-bitstream-vera
                         font-dejavu
                         gvfs
                         idesk
                         oxygen-icons
                         systole-wallpapers
                         thunar
                         ntfs-3g
                         xfce4-terminal
                         udisks
                         polkit
                         thunar-volman
                         git)
                   %base-packages))

 ;; Below is the list of system services.  To search for available
 ;; services, run 'guix system search KEYWORD' in a terminal.
 (services
  (append (list
           (set-xorg-configuration
            (xorg-configuration (keyboard-layout keyboard-layout)))
           (simple-service 'add-nonguix-substitutes
                           guix-service-type
                           (guix-extension
                            (substitute-urls
                             (append (list "https://substitutes.nonguix.org")
                                     %default-substitute-urls))
                            (authorized-keys
                             (append (list (plain-file "nonguix.pub"
                                                       "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))
                                     %default-authorized-guix-keys))))

           (service nftables-service-type
                    (nftables-configuration
                     (ruleset (local-file "etc/nftables.conf"))))

           (service sddm-service-type (sddm-configuration
                                       (auto-login-user "guest")
                                       (auto-login-session "fluxbox")))

           (service dicomd-service-type
                    (dicomd-configuration
                     (aetitle "PSYDICOM")
                     (output-directory "/var/dicom-store")))

           (service guix-home-service-type
                    `(("rafael" ,guest-home))))

          ;; This is the default list of services we are appending to.
          %desktop-services))


 (bootloader (bootloader-configuration
              (bootloader grub-bootloader)
              (targets (list "/dev/sda"))
              (keyboard-layout keyboard-layout)))
 (swap-devices (list (swap-space
                      (target (uuid
                               "1e7beb97-9a2c-45be-8790-3066fd7f4606")))))

 ;; The list of file systems that get "mounted".  The unique
 ;; file system identifiers there ("UUIDs") can be obtained
 ;; by running 'blkid' in a terminal.
 (file-systems (cons* (file-system
                       (mount-point "/")
                       (device (uuid
                                "f42bdbc1-65a2-46de-ac6f-0662b8c3f599"
                                'ext4))
                       (type "ext4")) %base-file-systems)))
