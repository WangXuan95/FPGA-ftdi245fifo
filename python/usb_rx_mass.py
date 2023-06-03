#-*- coding:utf-8 -*-
# Python3
#
# This program is a test of FPGA+FTDI USB chips (FT232H, FT600, or FT601)
# It sends 4 bytes to FTDI chip, and the FPGA will treat these 4 bytes as a length.
# Then the FPGA sends bytes of length to the computer, and the program should receive these bytes.
#
# The corresponding FPGA top-level design can be found in fpga_top_ft232h_tx_mass.v (if you are using FT232H or FT2232H chips)
#                                                   Or see fpga_top_ft600_rx_mass.v (if you are using an FT600 chip)
#


from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode          # see USB_FTX232H_FT60X.py

from random import randint
import time



TEST_COUNT = 50


if __name__ == '__main__':
    
    usb = USB_FTX232H_FT60X_sync245mode(device_to_open_list =
        (('FTX232H', 'USB <-> Serial Converter'   ),           # firstly try to open FTX232H (FT232H or FT2232H) device named 'USB <-> Serial Converter'. Note that 'USB <-> Serial Converter' is the default name of FT232H or FT2232H chip unless the user has modified it. If the chip's name has been modified, you can use FT_Prog software to look up it.
         ('FT60X'  , 'FTDI SuperSpeed-FIFO Bridge'))           # secondly try to open FT60X (FT600 or FT601) device named 'FTDI SuperSpeed-FIFO Bridge'. Note that 'FTDI SuperSpeed-FIFO Bridge' is the default name of FT600 or FT601 chip unless the user has modified it.
    )
    
    
    total_rx_len = 0
    
    time_start = time.time()
    
    for i in range (TEST_COUNT) :
        expect_len = randint(1, 10000000)                                                                           # random a length
        txdata = bytes( [ expect_len&0xff, (expect_len>>8)&0xff, (expect_len>>16)&0xff, (expect_len>>24)&0xff ] )   # convert length number to a 4-byte byte array (with type of 'bytes')
        
        usb.send(txdata)                                                                                            # send the 4 bytes to usb
        
        data = usb.recv(expect_len)                                                                                 # recv from usb
        
        rx_len = len(data)
        
        total_rx_len += rx_len
        time_total = time.time() - time_start
        data_rate  = total_rx_len / (time_total + 0.001) / 1e3
        
        print('[%d/%d]   rx_len=%d   total_rx_len=%d   data_rate=%.0f kB/s' % (i+1, TEST_COUNT, rx_len, total_rx_len, data_rate) )
        
        if expect_len != rx_len :
            print('*** expect_len (%d) and rx_len (%d) mismatch' % (expect_len, rx_len) )
            break

    usb.close()
