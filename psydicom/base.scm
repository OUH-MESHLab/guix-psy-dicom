(define-module (base)
  #:use-module (gnu)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu packages image-processing)
  #:use-module (gnu packages image-viewers)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages disk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages xfce)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages conky)
  #:use-module (gnu services ssh)
  #:use-module (gnu services networking)
  #:use-module (gnu services guix)
  #:use-module (guix-systole services dicomd-service)
  #:use-module (guix)
  #:use-module (guix-systole packages wallpapers)
  #:use-module (srfi srfi-1)
  #:export (%psydicom-username
            %psydicom-password
            %psydicom-admin-username
            %psydicom-admin-password
            %psydicom-user-accounts
            %psydicom-base-packages
            %psydicom-base-services
            %psydicom-user-home
            %guest-home
            %file-conkyrc
            %file-fluxbox-init
            %file-fluxbox-keys
            %file-fluxbox-menu
            %file-fluxbox-startup
            %file-ideskrc
            %file-idesk-icon-lnk
            %file-nftables-config))

;; Pull the username and password from the environment.
;; Note: (getenv VAR) returns #f if VAR isn’t bound,
;; so we wrap it with (or …) to supply a default.
(define %psydicom-username (or (getenv "PSYDICOM_USERNAME") "guest"))
(define %psydicom-password (or (getenv "PSYDICOM_PASSWORD") ""))
(define %psydicom-admin-username (or (getenv "PSYDICOM_ADMIN_USERNAME") "admin"))
(define %psydicom-admin-password (or (getenv "PSYDICOM_ADMIN_PASSWORD") "admin"))

;; Configuration files
(define %file-conkyrc (local-file "etc/conky/conky.conf"))
(define %file-fluxbox-init (local-file "etc/fluxbox/init"))
(define %file-fluxbox-keys (local-file "etc/fluxbox/keys"))
(define %file-fluxbox-menu (local-file "etc/fluxbox/menu"))
(define %file-fluxbox-startup (local-file "etc/fluxbox/startup"))
(define %file-ideskrc (local-file "etc/idesk/ideskrc"))
(define %file-idesk-icon-lnk (local-file "etc/idesk/DICOMStore.lnk"))
(define %file-nftables-config (local-file "etc/misc/nftables.conf"))

(define %psydicom-user-home
  (home-environment
    (services
     (cons*
      (service
       home-xdg-configuration-files-service-type
       `())
      (service
       home-files-service-type
       `((".fluxbox/init" ,%file-fluxbox-init)
         (".fluxbox/keys" ,%file-fluxbox-keys)
         (".fluxbox/startup" ,%file-fluxbox-startup)
         (".idesktop/DICOMStore.lnk" ,%file-idesk-icon-lnk)
         (".conkyrc" ,%file-conkyrc)
         (".ideskrc" ,%file-ideskrc)))
      %base-home-services))))

(define %psydicom-user-accounts
  (list
   (user-account
     (name %psydicom-username)
     (comment %psydicom-username)
     (password %psydicom-password)
     (group "users")
     (supplementary-groups '("dicom")))
   (user-account
     (name %psydicom-admin-username)
     (comment %psydicom-admin-username)
     (password %psydicom-admin-password)
     (group "users")
     (supplementary-groups '("audio" "video" "netdev" "wheel" "dicom")))))

(define %psydicom-base-packages
  (list dcmtk
        feh
        fluxbox
        font-bitstream-vera
        font-bitstream-vera
        font-dejavu
        gparted
        gvfs
        idesk
        oxygen-icons
        systole-wallpapers
        thunar
        vim
        xfce4-terminal
        conky))

(define %psydicom-base-services
  (list (service openssh-service-type)

        (service nftables-service-type
                 (nftables-configuration
                  (ruleset (local-file "etc/nftables.conf"))))

        (service dicomd-service-type
                 (dicomd-configuration
                  (aetitle "PSYDICOM")
                  (output-directory "/var/dicom-store")))

        (service guix-home-service-type
                 `((,%psydicom-username ,%psydicom-user-home)))))
