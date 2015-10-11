package app.DDSWave;

public class STM32_LGA {
	public byte DataBlocks;
	public byte TriggerValue;
	public byte TriggerMask;
	public byte TriggerWait;
	public short LGASampleRateDiv;
	public short LGASampleRate;

	public boolean SendLGA() {
		boolean err;
		try {
			BlueTooth.btbusy = true;
			err = !BlueTooth.BTPutInt(BlueTooth.CMD_LGASET);
			err |= !BlueTooth.BTPutByte(DataBlocks);
			err |= !BlueTooth.BTPutByte(TriggerValue);
			err |= !BlueTooth.BTPutByte(TriggerMask);
			err |= !BlueTooth.BTPutByte(TriggerWait);
			err |= !BlueTooth.BTPutShort(LGASampleRateDiv);
			err |= !BlueTooth.BTPutShort(LGASampleRate);
			err |= !BlueTooth.BTGetBytes(DataBlocks * 1024);
			return !err;
		} catch (Exception e) {
			return false;
		}
	}

}
