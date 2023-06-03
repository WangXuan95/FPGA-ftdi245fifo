#-*- coding:utf-8 -*-
# Python3
#
# This program is a test of FPGA+FTDI USB chips (FT232H, FT600, or FT601)
# It sends 16 bytes to FTDI chip. The FPGA immediately returns these data (loopback).
# The program will receive these bytes (they should be as same as the sended 16 bytes)
#
# The corresponding FPGA top-level design can be found in fpga_top_ft232h_loopback.v (if you are using FT232H or FT2232H chips)
#                                                   Or see fpga_top_ft600_loopback.v (if you are using an FT600 chip)
#


from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode          # see USB_FTX232H_FT60X.py



if __name__ == '__main__':
    
    usb = USB_FTX232H_FT60X_sync245mode(device_to_open_list =
        (('FTX232H', 'USB <-> Serial Converter'   ),           # firstly try to open FTX232H (FT232H or FT2232H) device named 'USB <-> Serial Converter'. Note that 'USB <-> Serial Converter' is the default name of FT232H or FT2232H chip unless the user has modified it. If the chip's name has been modified, you can use FT_Prog software to look up it.
         ('FT60X'  , 'FTDI SuperSpeed-FIFO Bridge'))           # secondly try to open FT60X (FT600 or FT601) device named 'FTDI SuperSpeed-FIFO Bridge'. Note that 'FTDI SuperSpeed-FIFO Bridge' is the default name of FT600 or FT601 chip unless the user has modified it.
    )
    
    
    txlen = usb.send(b'0123456789abcdef')
    
    print("%d B sent" % txlen)
    
    data = usb.recv(txlen*2)
    
    print("recv %d B : %s" % (len(data), str(data)) )

    usb.close()
