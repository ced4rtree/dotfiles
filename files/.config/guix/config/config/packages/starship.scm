;; Credit to TinHead on github for creating this package definition
;; Originally found at https://github.com/TinHead/th-guix-channel
;; I would've used their channel, but I only needed the one package

(define-module (config packages starship)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix licenses)
  #:use-module (nonguix build-system binary))

(define-public starship
  (package
    (name "starship")
    (version "1.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/starship/starship/releases/download/v"
             version
             "/starship-x86_64-unknown-linux-gnu.tar.gz"))
       (sha256
        (base32
         "1bjq6y3wfxanahw4rzqxl86kc4j3slrg8dixnhf5hf31yd57yydv"))))
    (build-system binary-build-system)
    (arguments
     `(#:install-plan
       `(("starship" "/bin/"))
       #:patchelf-plan
       `(("starship" ("gcc:lib" "glibc")))
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda* (#:key inputs #:allow-other-keys)
             (invoke "tar" "-xvzf" (assoc-ref inputs "source")))))))
    (inputs
     `(("gcc:lib" ,gcc "lib")
       ("glibc" ,glibc)))
    (native-inputs
     `(("gzip" ,gzip)))
    (synopsis "Starship is the minimal, blazing fast, and extremely customizable prompt for any shell!")
    (description "Starship is the minimal, blazing fast, and extremely customizable prompt for any shell!")
    (home-page "https://github.com/starship/starship")
    (license isc)))
