#-*- coding:utf-8 -*-
# Python3
#
# This program is a test of FPGA+FTDI USB chips (FT232H, FT600, or FT601)
# It sends random data block to FTDI chip. The blocks all ends with 0xFF. Except for the last byte, all other bytes are not 0xFF
# when the FPGA receives the block, it calculates its CRC. When meeting 0xFF, the FPGA send CRC of the block via FTDI chip
# Finally, the program will verify whether the CRC value is the same as the calculated CRC value.
#
# The corresponding FPGA top-level design can be found in fpga_top_ft232h_rx_crc.v (if you are using FT232H or FT2232H chips)
#                                                   Or see fpga_top_ft600_rx_crc.v (if you are using an FT600 chip)
#


from USB_FTX232H_FT60X import USB_FTX232H_FT60X_sync245mode          # see USB_FTX232H_FT60X.py

from random import randint
import time



def rand_data (minlen, maxlen) :
    minlen = max(1, minlen)
    maxlen = max(minlen, maxlen)
    length = randint(minlen, maxlen)
    array = [randint(0, 0xFE) for i in range(length)]
    return bytes(array)



def calc_crc (data) :
    TABLE_CRC = (0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c, 0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c)
    crc = 0xFFFFFFFF
    for byte in data :
        crc ^= byte
        crc = TABLE_CRC[crc & 0xF] ^ (crc >> 4)
        crc = TABLE_CRC[crc & 0xF] ^ (crc >> 4)
    return crc




data_list = [                                      # this list will contains several data blocks and their CRC
    [ data, calc_crc(data) ]
    for data in [                                  # Note that each block of data end with 0xFF, since FPGA start to send CRC when meeting 0xFF (see rx_calc_crc.v)
                                      b'\xFF' ,    # block length = 1
        rand_data( 1     , 1      ) + b'\xFF' ,    # block length = 2
        rand_data( 2     , 2      ) + b'\xFF' ,    # block length = 3
        rand_data(2000000, 3000000) + b'\xFF' ,    # block length = 2000001 ~ 3000001
        rand_data(2000000, 3000000) + b'\xFF' ,    # block length = 2000001 ~ 3000001
        rand_data(2000000, 3000000) + b'\xFF'      # block length = 2000001 ~ 3000001
    ]
]



TEST_COUNT = 50

if __name__ == '__main__':
    
    usb = USB_FTX232H_FT60X_sync245mode(device_to_open_list =
        (('FTX232H', 'USB <-> Serial Converter'   ),           # firstly try to open FTX232H (FT232H or FT2232H) device named 'USB <-> Serial Converter'. Note that 'USB <-> Serial Converter' is the default name of FT232H or FT2232H chip unless the user has modified it. If the chip's name has been modified, you can use FT_Prog software to look up it.
         ('FT60X'  , 'FTDI SuperSpeed-FIFO Bridge'))           # secondly try to open FT60X (FT600 or FT601) device named 'FTDI SuperSpeed-FIFO Bridge'. Note that 'FTDI SuperSpeed-FIFO Bridge' is the default name of FT600 or FT601 chip unless the user has modified it.
    )
    
    
    total_tx_len = 0
    
    time_start = time.time()
    
    for i in range (TEST_COUNT) :
        txdata, tx_crc = data_list[ randint(0, len(data_list)-1) ]                     # randomly select one data block, and get its CRC
        
        usb.send(txdata)
        
        rxdata = usb.recv(4)                                                           # recv 4 bytes
        rx_crc = (rxdata[3]<<24) + (rxdata[2]<<16) + (rxdata[1]<<8) + (rxdata[0]<<0)   # regard the 4 bytes as CRC
        
        total_tx_len += len(txdata)
        time_total = time.time() - time_start
        data_rate  = total_tx_len / (time_total + 0.001) / 1e3
        
        print('[%d/%d]   tx_len=%d   crc=%08x   total_tx_len=%d   data_rate=%.0f kB/s' % (i+1, TEST_COUNT, len(txdata), rx_crc, total_tx_len, data_rate) )
        
        if tx_crc != rx_crc :
            print('*** tx_crc (%08x) and rx_crc (%08x) mismatch' % (tx_crc, rx_crc) )
            break
    
    usb.close()
