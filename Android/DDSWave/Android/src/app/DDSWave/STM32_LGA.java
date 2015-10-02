package app.DDSWave;

import java.io.IOException;

public class STM32_LGA {
	public byte DataBlocks;
	public byte TriggerValue;
	public byte TriggerMask;
	public byte TriggerWait;
	public short LGASampleRateDiv;
	public short LGASampleRate;

	public static byte LGAData[] = new byte[DDSWave.LGASIZE];

	public boolean SendLGA() {
		boolean err;
		try {
			err = !BlueTooth.BTPutInt(BlueTooth.CMD_LGASET);
			err |= !BlueTooth.BTPutByte(DataBlocks);
			err |= !BlueTooth.BTPutByte(TriggerValue);
			err |= !BlueTooth.BTPutByte(TriggerMask);
			err |= !BlueTooth.BTPutByte(TriggerWait);
			err |= !BlueTooth.BTPutShort(LGASampleRateDiv);
			err |= !BlueTooth.BTPutShort(LGASampleRate);
			err |= !BTGetBytes(DataBlocks * 1024);
			return !err;
		} catch (Exception e) {
			return false;
		}
	}

	private static boolean BTGetBytes(int n) {
        try {
        	int bytes = 0;
        	while (bytes < n) {
               	bytes += DDSWave.mInputStream.read(LGAData,bytes,n-bytes);
        	}
        	return true;
        } catch (IOException e) {
        	return false;
        }
	}
	
}
