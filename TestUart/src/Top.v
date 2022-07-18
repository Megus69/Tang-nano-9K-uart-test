// UART TEST 
// 
// 16 bytes queue rx and tx .


module uartest (
    input sys_clk,          // clk input
    input sys_rst_n,        // reset input
    input  rxPin,
    output reg [5:0] led,    // 6 LEDS pin
    output txPin
);

reg [7:0] serRxBuffer[0:15];      // Buffer 16 bytes
reg [3:0] pntRxBuffer;            // Pointer where to start to transmit by uart
reg [3:0] pntToRxBuffer;          // Pointer where put the byte in the queue
reg [7:0] serTxBuffer[0:15];      // Buffer 16 bytes
reg [3:0] pntTxBuffer;            // Point where read the input buffer
reg [3:0] pntToTxBuffer;          // Point where is put the received buffer from uart
reg sendChar;                     // Reg for transmit input of uart


wire uartTransmit;
wire uartReceived;
wire [7:0]  rxBuffer;
wire [7:0]  txBuffer = serTxBuffer[pntTxBuffer];
wire isRecv;
wire isTran;
wire uartError;



// Led management

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        begin
            led <= 6'b000000;
        end
    else 
        led <= ~{isRecv, isTran, pntToRxBuffer};
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
            if (pntRxBuffer != pntToRxBuffer) 
                begin    
                    // Echo + 1
                    serTxBuffer[pntToTxBuffer] <= serRxBuffer[pntRxBuffer] + 8'd1;
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
                    if ((pntToRxBuffer + 4'd1) != pntRxBuffer) 
                        begin
                            serRxBuffer[pntToRxBuffer] <= rxBuffer;
                            pntToRxBuffer <= pntToRxBuffer + 4'd1;       
                        end
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
            sendChar <= 1'd0;
            tx_state <= TX_IDLE;
        end
    else
        begin
            sendChar <= haveToSend;
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
                            tx_state = TX_IDLE;
                        end
                end
            endcase
        end
end


// UART instantiation


assign uartTransmit = sendChar;

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
