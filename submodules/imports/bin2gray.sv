module bin2gray 
#(
    parameter WIDTH_P = 8
) (
  input logic [WIDTH_P-1:0] bin_i,
  output logic [WIDTH_P-1:0] gray_o
);
  integer i;
  always_comb begin
    gray_o[WIDTH_P-1] = bin_i[WIDTH_P-1]; 
    for (i = WIDTH_P-2; i >= 0; i--) begin
      gray_o[i] = bin_i[i+1] ^ bin_i[i];
    end
  end
endmodule