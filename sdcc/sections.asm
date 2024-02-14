; Assembly language file to define the additional sections.
; It's not possible to do this from C with sdcc.
;
; The contended memory area is 16384 to 32767 inclusive. The
; section described here starts just above the BASIC loader.
; This is a good place to store level data or anything else
; that will, at some point, need to be moved into the fast
; memory area (32768 upwards) for use in the program.
;
; The Z80 code loads in one chunk, starting at the first address
; here. The z88dk application maker utility by default assumes
; the program starts at the lowest address of the binary, which
; in this case is incorrect. i.e. it will build a loader which
; says:
;
; 10 CLEAR 24999
; 20 LOAD "" CODE 25000
; 30 RANDOMISE USR 25000
;
; So it'll try to execute this data block, which isn't going to
; end well.
;
; The solution is to add --usraddr=32768 to the application
; maker, which makes it produce this:
;
; 10 CLEAR 24999
; 20 LOAD "" CODE 25000
; 30 RANDOMISE USR 32768
;
; Which is what's required: load the code, with its data block
; first, into low memory (25000) then run the code from the
; correct origin.
;
; If the start of the code isn't at the nice, predictable
; location of 32768, you can add in the jump line shown below.
; Leave off the --usraddr option and the application maker will
; run the code at the lowest address, which is 25000. If that
; jump is there, the Z80 will jump straight to the start of the
; program. Costs 3 bytes.

SECTION CONTENDED
org 25000

;; __Start is the symbol for the start of the CRT code
;;
;;EXTERN __Start
;;jp     __Start