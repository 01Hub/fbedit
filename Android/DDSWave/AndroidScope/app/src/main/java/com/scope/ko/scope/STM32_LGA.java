package com.scope.ko.scope;

/**
 * Created by Ketil on 17.02.2016.
 */
public class STM32_LGA {
    public byte DataBlocks;
    public byte TriggerValue;
    public byte TriggerMask;
    public byte TriggerWait;
    public short LGASampleRateDiv;
    public short LGASampleRate;

    public String lgasrstr[] = {"1KHz","2KHz","5KHz","10KHz","20KHz","50KHz","100KHz","200KHz","500KHz","1MHz","2MHz","5MHz","10MHz","20MHz","40MHz"};
    public int lgasrint[] = {199999,99999,39999,19999,9999,3999,1999,999,399,199,99,39,19,9,4};
    public int lgatimediv[] = {10000000,5000000,2000000,1000000,500000,200000,100000,50000,20000,10000,5000,2000,1000,500,250};
    public boolean SendLGA() {
        boolean err = false;
        try {
            if (BlueTooth.btconnected) {
                BlueTooth.btbusy = true;
                err = !BlueTooth.BTPutInt(BlueTooth.CMD_LGASET);
                err |= !BlueTooth.BTPutByte(DataBlocks);
                err |= !BlueTooth.BTPutByte(TriggerValue);
                err |= !BlueTooth.BTPutByte(TriggerMask);
                err |= !BlueTooth.BTPutByte(TriggerWait);
                err |= !BlueTooth.BTPutShort(LGASampleRateDiv);
                err |= !BlueTooth.BTPutShort(LGASampleRate);
                err |= !BlueTooth.BTGetBytes(DataBlocks * 1024);
            }
            return !err;
        } catch (Exception e) {
            return false;
        }
    }

}
