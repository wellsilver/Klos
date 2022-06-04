#![no_std] 
#![no_main] // disable libaries (nothing that supports them) and rusty things

use core::panic::PanicInfo;

/// if computer == pain {
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle] // bootloader loves this one
pub extern "C" fn _start() -> ! {
    loop {}
}