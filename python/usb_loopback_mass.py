#-*- coding:utf-8 -*-
# Python3
#
# This program is a test of FPGA+FTDI USB chips (FT232H, FT600, or FT601)
# It sends random data blocks to FTDI chip. The FPGA immediately returns these data (loopback).
# The program will receive these data blocks and compare them with the previously sent data blocks (they should be the same)
#
# The corresponding FPGA top-level design can be found in fpga_top_ft232h_loopback.v (if you are using FT232H or FT2232H chips)
#                                                   Or see fpga_top_ft600_loopback.v (if you are using an FT600 chip)
#


from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode          # see USB_FTX232H_FT60X.py

from random import randint



def rand_data (minlen, maxlen) :
    minlen = max(1, minlen)
    maxlen = max(minlen, maxlen)
    length = randint(minlen, maxlen)
    array = [randint(0, 255) for i in range(length)]
    return bytes(array)



TEST_COUNT = 2000


if __name__ == '__main__':
    
    usb = USB_FTX232H_FT60X_sync245mode( device_to_open_list =
        (('FTX232H', 'USB <-> Serial Converter'   ),           # firstly try to open FTX232H (FT232H or FT2232H) device named 'USB <-> Serial Converter'. Note that 'USB <-> Serial Converter' is the default name of FT232H or FT2232H chip unless the user has modified it. If the chip's name has been modified, you can use FT_Prog software to look up it.
         ('FT60X'  , 'FTDI SuperSpeed-FIFO Bridge'))           # secondly try to open FT60X (FT600 or FT601) device named 'FTDI SuperSpeed-FIFO Bridge'. Note that 'FTDI SuperSpeed-FIFO Bridge' is the default name of FT600 or FT601 chip unless the user has modified it.
    )
    
    
    total_len = 0
    
    for i in range(TEST_COUNT) :
        txdata = rand_data(1, 2000)                            # randomly generate data (with type of 'bytes')
        usb.send(txdata)                                       # send data
        rxdata = usb.recv( len(txdata)  )                      # receive data, it will get the same data since the usb is loopback in FPGA (see fpga_top_ft232h_loopback.v or fpga_top_ft600_loopback.v)
        
        total_len += len(txdata)
        
        if i % 100 == 0 :
            print('[%d/%d]   total_len=%d' % (i+1, TEST_COUNT, total_len) )
        
        if txdata != rxdata :                                  # check if send data and receive data are the same
            print('*** txdata and rxdata mismatch' )
            print('txdata =', txdata)
            print('rxdata =', rxdata)
            break
    
    usb.close()
