// UART TEST 
// 
// 16 bytes queue rx and tx .


module uartest (
    input sys_clk,          // clk input
    input sys_rst_n,        // reset input
    input  rxPin,
    input  sendFrame,
    output reg [5:0] led,    // 6 LEDS pin
    output txPin
);

reg [7:0] serRxBuffer[0:31];      // Buffer 16 bytes
reg [3:0] pntRxBuffer;            // Pointer where to start to transmit by uart
reg [3:0] pntToRxBuffer;          // Pointer where put the byte in the queue
reg [7:0] serTxBuffer[0:31];      // Buffer 16 bytes
reg [3:0] pntTxBuffer;            // Point where read the input buffer
reg [3:0] pntToTxBuffer;          // Point where is put the received buffer from uart


wire uartTransmit;
wire uartReceived;
wire [7:0]  rxBuffer;
wire [7:0]  txBuffer = serTxBuffer[pntTxBuffer];
wire isRecv;
wire isTran;
wire uartError;

wire startFrame;

edge_detector dect1( sys_clk, !sendFrame, startFrame);


// Led management

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        begin
            led <= 6'b000000;
        end
    else 
        led <= ~{uartError, isRecv, pntToRxBuffer};
end


// Echo manager - Gets from rx queue and put in tx queue next character

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        begin
            pntRxBuffer <= 4'd0;
            pntToTxBuffer <= 4'd0;
        end
    else 
        begin
            if (startFrame) 
                begin
                    pntToTxBuffer <= pntToTxBuffer + 4'd8;
                    serTxBuffer[pntToTxBuffer] = 8'h31;
                    serTxBuffer[pntToTxBuffer + 4'd1] = 8'h32;
                    serTxBuffer[pntToTxBuffer + 4'd2] = 8'h33;
                    serTxBuffer[pntToTxBuffer + 4'd3] = 8'h34;
                    serTxBuffer[pntToTxBuffer + 4'd4] = 8'h35;
                    serTxBuffer[pntToTxBuffer + 4'd5] = 8'h36;
                    serTxBuffer[pntToTxBuffer + 4'd6] = 8'h37;
                    serTxBuffer[pntToTxBuffer + 4'd7] = 8'h38;
                end
            else
                if (pntRxBuffer != pntToRxBuffer) 
                    begin    
                        // Echo + 1
                        serTxBuffer[pntToTxBuffer] <= serRxBuffer[pntRxBuffer];
                        pntRxBuffer <= pntRxBuffer + 4'd1;
                        pntToTxBuffer <= pntToTxBuffer + 4'd1;
                end
        end
end


// Puts on queue received char

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        begin
            pntToRxBuffer <= 4'd0;
        end
    else 
        begin
            if (uartReceived) 
                begin
                    serRxBuffer[pntToRxBuffer] <= rxBuffer;
                    pntToRxBuffer <= pntToRxBuffer + 4'd1;        
                end
        end
end


// Transmits the queue 

parameter TX_IDLE = 0;
parameter TX_SENDING = 1;
reg [1:0] tx_state = TX_IDLE;

wire haveToSend = (pntToTxBuffer != pntTxBuffer) & (!isTran);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        begin
            pntTxBuffer <= 4'd0;
            tx_state <= TX_IDLE;
        end
    else
        begin
            case (tx_state)
                TX_IDLE: begin
                    if (haveToSend) begin
                        tx_state = TX_SENDING;
                    end
                end
                TX_SENDING: begin
                    if (!isTran) 
                        begin
                            pntTxBuffer <= pntTxBuffer + 4'd1;
                            if ((pntTxBuffer + 4'd1) == pntToTxBuffer)  // Finito
                                tx_state = TX_IDLE;
                        end
                end
            endcase
        end
end


// UART instantiation


assign uartTransmit = haveToSend & (tx_state == TX_SENDING);

uart uart_inst1(
    .clk(sys_clk),              // The master clock for this module
    .rst(!sys_rst_n),           // Synchronous reset.
    .rx(rxPin),                 // Incoming serial line
    .tx(txPin),                 // Outgoing serial line
    .transmit(uartTransmit),    // Signal to transmit
    .tx_byte(txBuffer),         // Byte to transmit
    .received(uartReceived),    // Indicated that a byte has been received.
    .rx_byte(rxBuffer),         // Byte received
    .is_receiving(isRecv),      // Low when receive line is idle.
    .is_transmitting(isTran),   // Low when transmit line is idle.
    .recv_error(uartError)      // Indicates error in receiving packet.
    );


endmodule
