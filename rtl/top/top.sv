module top (
    input logic [0:0] clk_12mhz_i,
    input logic [0:0] reset_n_async_unsafe_i,
    input logic [3:1] button_async_unsafe_i,
    output logic [0:0] tx_main_clk_o,
    output logic [0:0] tx_lr_clk_o,
    output logic [0:0] tx_data_clk_o,
    output logic [0:0] tx_data_o,
    output logic [0:0] rx_main_clk_o,
    output logic [0:0] rx_lr_clk_o,
    output logic [0:0] rx_data_clk_o,
    input logic [0:0] rx_data_i,
    output logic [5:1] led_o
);

    logic [0:0] clk_12mhz_o;
    logic [0:0] clk_25mhz_o;
    logic [0:0] axis_clk;

    logic [0:0] reset_25_n_sync_r;
    logic [0:0] reset_25_r;

    logic [0:0] reset_12_n_sync_r;
    logic [0:0] reset_12_r;

    always_ff @(posedge clk_25mhz_o) begin
        reset_25_n_sync_r <= reset_n_async_unsafe_i;
        reset_25_r <= ~reset_25_n_sync_r;
    end

    always_ff @(posedge clk_12mhz_o) begin
        reset_12_n_sync_r <= reset_n_async_unsafe_i;
        reset_12_r <= ~reset_12_n_sync_r;
    end

    logic [31:0] axis_tx_data;
    logic [23:0] axis_tx_data_low;
    logic [0:0] axis_tx_valid;
    logic [0:0] axis_tx_ready;
    logic [0:0] axis_tx_last;

    logic [31:0] axis_rx_data;
    logic [0:0] axis_rx_valid;
    logic [0:0] axis_rx_ready;
    logic [0:0] axis_rx_last;

    (* blackbox *)
    SB_PLL40_2_PAD 
    #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),
        .DIVF(7'd59),
        .DIVQ(3'd5),
        .FILTER_RANGE(3'b001)
    ) pll_inst (
        .PACKAGEPIN(clk_12mhz_i),
        .PLLOUTGLOBALA(clk_12mhz_o),
        .PLLOUTGLOBALB(clk_25mhz_o),
        .RESETB(1'b1),
        .BYPASS(1'b0)
    );

    assign axis_clk = clk_25mhz_o;
    assign axis_tx_data = {8'b0, axis_tx_data_low};

    axis_i2s2 
    #()
    i2s2_inst
    (
        .axis_clk(axis_clk),
        .axis_resetn(~reset_25_r),
    
        .tx_axis_c_data(axis_tx_data),
        .tx_axis_c_valid(axis_tx_valid),
        .tx_axis_c_ready(axis_tx_ready),
        .tx_axis_c_last(axis_tx_last),
    
        .rx_axis_p_data(axis_rx_data),
        .rx_axis_p_valid(axis_rx_valid),
        .rx_axis_p_ready(axis_rx_ready),
        .rx_axis_p_last(axis_rx_last),
    
        .tx_mclk(tx_main_clk_o),
        .tx_lrck(tx_lr_clk_o),
        .tx_sclk(tx_data_clk_o),
        .tx_sdout(tx_data_o),
        .rx_mclk(rx_main_clk_o),
        .rx_lrck(rx_lr_clk_o),
        .rx_sclk(rx_data_clk_o),
        .rx_sdin(rx_data_i),
    );

    logic [0:0] valid_li;
    logic [0:0] ready_lo;
    logic [23:0] data_right_li;
    logic [23:0] data_left_li;

    logic [0:0] valid_lo;
    logic [0:0] ready_li;
    logic [23:0] data_right_lo;
    logic [23:0] data_left_lo;

    logic [23:0] sipo_data_o1;
    logic [23:0] sipo_data_o0;

    bsg_serial_in_parallel_out_full
    #()
    sipo_inst
    (
        clk_25mhz_o,
        reset_25_r,
        axis_rx_valid,
        axis_rx_ready,
        valid_li,
        ready_lo & valid_li,
        sipo_data_o1,
        axis_rx_data[23:0],
        sipo_data_o0
    );

    assign {data_right_li, data_left_li} = {sipo_data_o1, sipo_data_o0};

    logic [24:0] piso_data_i1;
    logic [24:0] piso_data_i0;

    assign piso_data_i1 = {data_right_lo, 1'b1};
    assign piso_data_i0 = {data_left_lo, 1'b0};

    bsg_parallel_in_serial_out
    #()
    piso_inst
    (
        clk_25mhz_o,
        reset_25_r,
        valid_lo,
        ready_li,
        axis_tx_valid,
        axis_tx_ready,
        {axis_tx_data_low, axis_tx_last},
        piso_data_i1,
        piso_data_i0
    );

    logic [0:0] _ready_o;
    logic [0:0] _valid_o;
    logic [47:0] _data_o;

    fifo_async 
    #(
        .WIDTH_P(48),
        .DEPTH_P(16)
    ) 
    fifo_down 
    (
        .pclk_i(clk_25mhz_o),
        .cclk_i(clk_12mhz_o),
        .rstn_i(~(reset_25_r | reset_12_r)),
        .data_i({data_left_li, data_right_li}),
        .valid_i(valid_li),
        .ready_i(_ready_o),
        .valid_o(_valid_o),
        .ready_o(ready_lo),
        .data_o(_data_o)
    );

    fifo_async 
    #(
        .WIDTH_P(48),
        .DEPTH_P(16)
    ) 
    fifo_up 
    (
        .pclk_i(clk_12mhz_o),
        .cclk_i(clk_25mhz_o),
        .rstn_i(~(reset_25_r | reset_12_r)),
        .data_i(_data_o),
        .valid_i(_valid_o),
        .ready_i(ready_li),
        .valid_o(valid_lo),
        .ready_o(_ready_o),
        .data_o({data_left_lo, data_right_lo})
    );

endmodule
