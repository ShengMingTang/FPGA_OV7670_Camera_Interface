`timescale 1ns / 1ps

// @@ original clk (forked) is supposed to be 50MHz
// @@ basys3 has 100MHz clock

module top_module(
    // ! @@ // rst_n is not as expected
	// input wire clk,rst_n,
    input wire clk,rst, // @@ rst_n is not as expected

	input wire[3:0] key, //key[1:0] for brightness control , key[3:2] for contrast control
	
	// camera pinouts
	input wire cmos_pclk,cmos_href,cmos_vsync,
	input wire[7:0] cmos_db,
	inout cmos_sda,cmos_scl, 
	output wire cmos_rst_n, cmos_pwdn, cmos_xclk,
	
	// Debugging
	output[3:0] led, 
	
	// controller to sdram
	// output wire sdram_clk,
	// output wire sdram_cke, 
	// output wire sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n, 
	// output wire[12:0] sdram_addr,
	// output wire[1:0] sdram_ba, 
	// output wire[1:0] sdram_dqm, 
	// inout[15:0] sdram_dq,
	
	// VGA output
	// output wire[4:0] vga_out_r,
	// output wire[5:0] vga_out_g,
	// output wire[4:0] vga_out_b,
	// output wire vga_out_vs,vga_out_hs
	
	// @@ VGA output
	output wire[3:0] vga_out_r4,
	output wire[3:0] vga_out_g4,
	output wire[3:0] vga_out_b4,
	output wire vga_out_vs,vga_out_hs
);

// ========================= Start of Code =========================
	wire f2s_data_valid;
	wire[9:0] data_count_r;
	wire[15:0] dout,din;
	wire clk_sdram;
	wire empty_fifo;
	wire clk_vga;
	wire state;
	wire rd_en;

	// @@
	wire clk_50MHz;
	wire clk_25MHz;
    wire clk_24MHz;
	wire [3:0] vga_out_r;
	wire [3:0] vga_out_g;
	wire [3:0] vga_out_b;

    // @@ reset
    wire rst_n;
    assign rst_n = ~rst;

    /*
	camera_interface m0 //control logic for retrieving data from camera, storing data to asyn_fifo, and  sending data to sdram
	(
		.clk(clk),
		.clk_100(clk_sdram),
		.rst_n(rst_n),
		.key(key),
		//asyn_fifo IO
		.rd_en(f2s_data_valid),
		.data_count_r(data_count_r),
		.dout(dout),
		//camera pinouts
		.cmos_pclk(cmos_pclk),
		.cmos_href(cmos_href),
		.cmos_vsync(cmos_vsync),
		.cmos_db(cmos_db),
		.cmos_sda(cmos_sda),
		.cmos_scl(cmos_scl), 
		.cmos_rst_n(cmos_rst_n),
		.cmos_pwdn(cmos_pwdn),
		.cmos_xclk(cmos_xclk),
		//Debugging
		.led(led)
	);
    sdram_interface m1 //control logic for writing the pixel-data from camera to sdram and reading pixel-data from sdram to vga
    (
        .clk(clk_sdram),
        .rst_n(rst_n),
        //asyn_fifo IO
        .clk_vga(clk_vga),
        .rd_en(rd_en),
        .data_count_r(data_count_r),
        .f2s_data(dout),
        .f2s_data_valid(f2s_data_valid),
        .empty_fifo(empty_fifo),
        .dout(din),
        //controller to sdram
        .sdram_cke(sdram_cke), 
        .sdram_cs_n(sdram_cs_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_we_n(sdram_we_n), 
        .sdram_addr(sdram_addr),
        .sdram_ba(sdram_ba), 
        .sdram_dqm(sdram_dqm),
        .sdram_dq(sdram_dq)
	);
    vga_interface m2 //control logic for retrieving data from sdram, storing data to asyn_fifo, and sending data to vga
    (
        .clk(clk),
        .rst_n(rst_n),
        //asyn_fifo IO
        .empty_fifo(empty_fifo),
        .din(din),
        .clk_vga(clk_vga),
        .rd_en(rd_en),
        //VGA output
        .vga_out_r(vga_out_r),
        .vga_out_g(vga_out_g),
        .vga_out_b(vga_out_b),
        .vga_out_vs(vga_out_vs),
        .vga_out_hs(vga_out_hs)
	);
	//ERROR APPEARS IF ODDR2 IS ROUTED INSIDE THE FPGA INSTEAD OF BEING DIRECTLY CONNECTED TO OUTPUT (so we bring this outside)
    ODDR2#(.DDR_ALIGNMENT("NONE"), .INIT(1'b0),.SRTYPE("SYNC")) oddr2_primitive
    (
		.D0(1'b0),
		.D1(1'b1),
		.C0(clk_sdram),
		.C1(~clk_sdram),
		.CE(1'b1),
		.R(1'b0),
		.S(1'b0),
		.Q(sdram_clk)
	);
	//SDRAM clock
	dcm_165MHz m3
	(
        // Clock in ports
        .clk(clk),      // IN
        // Clock out ports
        .clk_sdram(clk_sdram),     // OUT
        // Status and control signals
        .RESET(RESET),// IN
        .LOCKED(LOCKED)
    );      // OUT
    */

    clock_divisor clk_wiz_0_inst(
      .clk(clk),//clk_100
	  .clk0(clk_50MHz),
      .clk1(clk_25MHz),
      .clk22(clk_22)
    );

    wire wr_en;
    wire [15:0] pixel_q;
    reg vsync_1, vsync_2;
    camera_interface m0 //control logic for retrieving data from camera, storing data to asyn_fifo, and  sending data to sdram
	(
		.clk(clk_50MHz), // original clk (50HMz)
		// @@
        // .clk_100(clk_sdram),
        .clk_100(clk),
		.rst_n(rst_n),
		.key(key),
		//asyn_fifo IO
		.rd_en(f2s_data_valid),
		.data_count_r(data_count_r),
		.dout(dout),
		//camera pinouts
		.cmos_pclk(cmos_pclk),
		.cmos_href(cmos_href),
		.cmos_vsync(cmos_vsync),
		.cmos_db(cmos_db),
		.cmos_sda(cmos_sda),
		.cmos_scl(cmos_scl), 
		.cmos_rst_n(cmos_rst_n),
		.cmos_pwdn(cmos_pwdn),
		.cmos_xclk(cmos_xclk),
		//Debugging
		.led(led)

        // @@ added
        ,
        .wr_en(wr_en),
        .pixel_q(pixel_q),
        .vsync_1(vsync_1),
        .vsync_2(vsync_2)
	);

    wire [16:0] pixel_addr;
    wire [9:0]h_cnt;
    wire [9:0]v_cnt;
    wire valid; 

    // ! @@ generate write pixel address
    // generate correct pixel_addr_wr to write
    wire [16:0] pixel_addr_wr;
    //reg [18:0] pixel_addr;
    reg [18:0] pixel_addr_wr_counter, pixel_addr_wr_counter_next;

    

    always @(posedge wr_en or posedge rst or posedge vsync_1) begin
        if(rst || vsync_1) begin
            pixel_addr_wr_counter = 19'b0;
        end
        else begin
            pixel_addr_wr_counter = pixel_addr_wr_counter_next;
        end
    end
    
    // localparam WIDTH=660, HEIGHT=490;
    // @@ small horizontal shift and vertical shift
    localparam WIDTH=640, HEIGHT=480;
    // localparam WIDTH=320, HEIGHT=240;

    // count in the resolution of 640x480
    always @(*) begin
        if (pixel_addr_wr_counter == (WIDTH*HEIGHT)-1) begin
            pixel_addr_wr_counter_next = 19'b0;
        end
        else begin
            pixel_addr_wr_counter_next = pixel_addr_wr_counter + 1'b1;
        end
    end
    // from 640x480 to 320x240
    assign pixel_addr_wr =  
        (320*(pixel_addr_wr_counter/WIDTH/2) + (pixel_addr_wr_counter%WIDTH/2)) % 76800;
    // assign pixel_addr_wr =  
    //     320*(pixel_addr_wr_counter/WIDTH) + (pixel_addr_wr_counter%WIDTH);

    // reg [9:0] x_cnt, y_cnt;
    // // reg [9:0] x_cnt_next;
    // reg [16:0] pixel_addr_wr;

    // always @(*) begin
    //     if(cmos_vsync) y_cnt = 10'd0;
    //     else if(cmos_href)begin
    //         y_cnt = y_cnt + 1;
    //         if(wr_en) x_cnt = x_cnt + 1'b1;
    //         else x_cnt = x_cnt;
    //     end
    //     else x_cnt = 10'd0;
    // end
    // always @(posedge wr_en or negedge cmos_href ) begin
    //     if(~cmos_href) x_cnt <= 10'd0;
    //     else x_cnt <= x_cnt + 1'b1;
    
    // end

    // always @(*) begin
    //     if(cmos_href == 1'b0)
    //         x_cnt_next = 10'd0;
    //     else
    //         x_cnt_next = x_cnt + 1'b1;
    // end

    // always @(posedge cmos_vsync or posedge cmos_href) begin
    //     if(cmos_vsync) y_cnt <= 10'd0;
    //     else begin
    //         y_cnt <= y_cnt + 1'b1;
    //     end
    // end

    // always @(*) begin
    //     pixel_addr_wr = 320*((y_cnt>>1)) + (x_cnt>>1);
    // end

    // 320x240, combinational logic
    mem_addr_gen mem_addr_gen_inst
    (
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );
    vga_controller ctrl
    (
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(vga_out_hs),
        .vsync(vga_out_vs),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;
    assign {vga_out_r4, vga_out_g4, vga_out_b4} = (valid==1'b1) ? {vgaRed, vgaGreen, vgaBlue} : 12'h0;
    
    // simple dual port
    blk_mem_gen_0 blk_mem_gen_0_inst 
    (
        // read
        .clkb(clk_25MHz),
        // .web(1'b0),
        .addrb(pixel_addr),
        .doutb( {vgaRed, vgaGreen, vgaBlue}),
        // .clka(clk_sdram),
        .clka(clk),
        // ! @@ write
        .wea(wr_en 
            // && ((pixel_addr_wr_counter%WIDTH/2) < 320) 
            // && ((pixel_addr_wr_counter/WIDTH/2) < 240)
        ),

        .addra(pixel_addr_wr),
        //RGB
        .dina({pixel_q[15:12], pixel_q[10:7], pixel_q[4:1]})
    ); 

    // ! @@
    //control logic for retrieving data from sdram, storing data to asyn_fifo, and sending data to vga
    // vga_interface m2
    // (
	// 	.clk(clk_50MHz), // original clk (50MHz)
	// 	.rst_n(rst_n),
	// 	//asyn_fifo IO
	// 	.empty_fifo(1'b0),
	// 	.din({vga_out_r4, vga_out_g4, vga_out_b4}),
	// 	.clk_vga(clk_vga),
	// 	.rd_en(rd_en),
	// 	//VGA output
	// 	.vga_out_r(vga_out_r),
	// 	.vga_out_g(vga_out_g),
	// 	.vga_out_b(vga_out_b),
	// 	.vga_out_vs(vga_out_vs),
	// 	.vga_out_hs(vga_out_hs),
	// 	.pixel_x(pixel_x),
	// 	.pixel_y(pixel_y)
    // );
    
    // ! @@ do we need such fast clock
    // use 100MHz is enough ?
    // dcm_165MHz m3
	// (
    //     // Clock in ports
    //     .clk(clk),      // IN
    //     // Clock out ports
    //     .clk_sdram(clk_sdram),     // OUT
    //     // Status and control signals
    //     .RESET(RESET),// IN
    //     .LOCKED(LOCKED) // OUT
    // );

    wire LOCKED;
    dcm_165MHz m3
	(
        // Clock in ports
        .clk_in1(clk),      // IN
        // Clock out ports
        .clk_out1(clk_sdram),     // OUT
        // Status and control signals
        .reset(rst),// IN
        .locked(LOCKED) // OUT
    );
    // @@ rgb565 to rgb444
    // assign vga_out_r4 = vga_out_r[4:1];
	// assign vga_out_g4 = vga_out_g[5:2];
	// assign vga_out_b4 = vga_out_b[4:1];
    wire LOCK;
    dcm_24MHz m4
	(
        // Clock in ports
        .clk_in1(clk_50MHz),      // IN
        // Clock out ports
        .clk_out1(clk_24MHz),     // OUT
        // Status and control signals
        .reset(rst),// IN
        .locked(LOCK) // OUT
    );
endmodule
