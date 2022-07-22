module edge_detector( clk, in, out);

input clk;
input in;
output out;

reg old_sig;
reg out = 0;


always @(posedge clk)
  begin
 	 out <= (~old_sig) & in;
	 old_sig <= in;
  end	

endmodule
