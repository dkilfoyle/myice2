module RAM #(
	parameter integer WORDS = 1288/4
) (
	input clk,
	input [3:0]  wmask,
	input [21:0] word,
  input is_ram,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];

  // Initialize the RAM with the generated firmware hex file.
   initial begin
      $readmemh("../firmware.hex", mem); 
   end

	always @(posedge clk) begin
    if (is_ram) begin
      if (wmask[0]) mem[word][ 7: 0] <= wdata[ 7: 0];
      if (wmask[1]) mem[word][15: 8] <= wdata[15: 8];
      if (wmask[2]) mem[word][23:16] <= wdata[23:16];
      if (wmask[3]) mem[word][31:24] <= wdata[31:24];
    end
		rdata <= mem[word];
	end
endmodule