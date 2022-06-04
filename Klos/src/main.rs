#![no_std] // don't link the Rust standard library
#![no_main] // disable all Rust-level entry points

use core::panic::PanicInfo;

fn begin() -> ! {
	// Use VGA later
}

#[no_mangle] // don't mangle the name of this function
pub extern "C" fn _start() -> ! {
    // the start thing
    loop {}
}

/// This function is called on panic.
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}