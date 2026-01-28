module gray2bin 
#(
    parameter WIDTH_P = 8
) (
  input logic [WIDTH_P-1:0] gray_i,
  output logic [WIDTH_P-1:0] bin_o
);
  integer i;
  always_comb begin
    bin_o[WIDTH_P-1] = gray_i[WIDTH_P-1];
    for (i = WIDTH_P-2; i >= 0; i--) begin
      bin_o[i] = bin_o[i+1] ^ gray_i[i];
    end
  end
endmodule