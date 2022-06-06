#![no_std] 
#![no_main] // disable libaries (nothing that supports them) and rusty things

use core::panic::PanicInfo;
mod vga_buffer; // print! and println!

/// if computer == pain {
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
  loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
  print!("Hello World!");
  loop {}
}