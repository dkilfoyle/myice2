// sources
// https://github.com/sam210723/fpga
// https://github.com/BrunoLevy/learn-fpga


`include "cpu.v"
`include "ram.v"
`include "uart.v"

localparam IO_UART_DAT_bit              = 1;  // RW write: data to send (8 bits) read: received data (8 bits)
localparam IO_UART_CNTL_bit             = 2;  // R  status. bit 8: valid read data. bit 9: busy sending

module soc (
	input clk,
	input RESET,

	input         io_ready,
	output [ 3:0] io_wstrb,
	output [31:0] io_addr,
	output [31:0] io_wdata,
	input  [31:0] io_rdata,

	output TXD,
	input  RXD,
);
	parameter integer MEM_WORDS = 12288/4;

  // A little delay for sending the reset signal after startup.
  // Explanation here: (ice40 BRAM reads incorrect values during first cycles).
  reg [15:0] reset_cnt = 0;
  wire       reset = &reset_cnt;
  always @(posedge clk,negedge RESET) begin
    if(!RESET) begin
	    reset_cnt <= 0;
    end else begin
	    reset_cnt <= reset_cnt + !reset;
    end
  end

  // memory map:
  //   address[21:2] RAM word address (4 Mb max).
  //   address[23:22]   00: RAM
  //                    01: IO page (1-hot)  (starts at 0x400000)

  wire mem_address_is_io  =  mem_address[22];
  wire mem_address_is_ram = !mem_address[22];

  // The memory bus.
  wire [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
  wire  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
  wire [31:0] mem_rdata;   // processor <- (mem and peripherals) 
  wire [31:0] mem_wdata;   // processor -> (mem and peripherals)
  wire        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
  wire        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
  wire        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
  wire        mem_wstrb = |mem_wmask; // mem write strobe, goes high to initiate memory write (deduced from wmask)
  wire [19:0] ram_word_address = mem_address[21:2]; // word offset (array index) in ram page

  // IO bus.
  reg  [31:0] io_rdata; 
  wire [31:0] io_wdata = mem_wdata;
  wire        io_rstrb = mem_rstrb && mem_address_is_io;
  wire        io_wstrb = mem_wstrb && mem_address_is_io;
  wire [19:0] io_word_address = mem_address[21:2]; // word offset in io page
  wire	      io_rbusy; 
  wire        io_wbusy;
  
  assign      mem_rbusy = io_rbusy;
  assign      mem_wbusy = io_wbusy; 

	wire [31:0] ram_rdata;

  RAM #(
		.WORDS(MEM_WORDS)
	) ram (
		.clk(clk),
		.wmask(mem_wmask),
		.word(ram_word_address),
    .is_ram(mem_address_is_ram),
		.wdata(mem_wdata),
		.rdata(ram_rdata)
	);

	FemtoRV32 cpu (
    .clk        (clk),			
    .mem_addr   (mem_address),
    .mem_wdata  (mem_wdata),
    .mem_wmask  (mem_wmask),
    .mem_rdata  (mem_rdata),
    .mem_rstrb  (mem_rstrb),
    .mem_rbusy  (mem_rbusy),
    .mem_wbusy  (mem_wbusy),
	);

  wire        uart_brk;
  wire [31:0] uart_rdata;

  UART uart(
    .clk      (clk),
    .rstrb    (io_rstrb),	     	     
    .wstrb    (io_wstrb),
    .sel_dat  (io_word_address[IO_UART_DAT_bit]),
    .sel_cntl (io_word_address[IO_UART_CNTL_bit]),	     
    .wdata    (io_wdata),
    .rdata    (uart_rdata),
    .RXD      (RXD),
    .TXD      (TXD),
    .brk      (uart_brk)
  );


endmodule