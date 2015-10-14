package app.DDSWave;

public class STM32_SCP {

	public byte SampleRateSet = 0;
	public byte PixDiv = DDSWave.WAVEGRID;
	public byte nDiv = DDSWave.WAVEGRIDX;
	public byte Mag = 0;
	public byte SubSampling = 0;
	public byte Trigger = 1;
	public byte Triple = 1;
	public byte Auto = 0;
	public short TriggerLevel = (short)(13.65 * 150.0);
	public short VPos = (short)(13.65 * (150.0 + 13.0));
	public int TimeDiv = 1000000;
	public int SampleRate = 10000000;


	public byte[] srset = {0x5F,0x57,0x4F,0x5E,0x5D,0x47,0x56,0x5C,0x55,0x4E,0x54,0x5B,0x4D,0x53,0x4C,0x5A,0x46,0x4B,0x45,0x52,0x59,0x44,0x51,0x3F,0x3E,0x3D,0x3C,0x3B,0x2F,0x2E,0x39,0x2D,0x38,0x2C,0x2B,0x2A,0x36,0x29,0x1F,0x28,0x1E,0x1D,0x1C,0x26,0x1B,0x1A,0x19,0x24,0x18,0x17,0x16,0x22,0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01,0x00};
	public  short[] stset = {3,15,28,56,84,112,144,480};
	public String scpvdstr[] = {"1mV","2mV","5mV","10mV","20mV","50mV","100mV","200mV","500mV"};

	public String scptdstr[] = {"100ns","200ns","500ns","1us","2us","5us","10us","20us","50us","100us","200us","500us","1ms","2ms","5ms","10ms","20ms","50ms","100ms","200ms","500ms"};
	public int scptdint[] = {100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000,2000000,5000000,10000000,20000000,50000000,100000000,200000000,500000000};

	public int scpfrq = 5000;

	private static int BTToInt(int i) {
    	return (BlueTooth.btreadbuffer[i+2] & 0xFF) << 16 | (BlueTooth.btreadbuffer[i+1] & 0xFF) << 8 | (BlueTooth.btreadbuffer[i+0] & 0xFF);
    }

	public String SendSCP() {
		boolean err;
		int f, g, i, j, n;
		String s = "";
		try {
			BlueTooth.btbusy = true;
			err = !BlueTooth.BTPutInt(BlueTooth.CMD_SCP2SET);
			if (BlueTooth.BTGetBytes(8)) {
				scpfrq = BlueTooth.BTToInt(4);
				if (scpfrq >= 1000000) {
					s = String.format("%.3f",((double)(scpfrq / 1000000.0))) + "MHz";
				} else if (scpfrq >= 1000) {
					s = String.format("%.3f",((double)(scpfrq / 1000.0))) + "KHz";
				} else {
					s = "" + scpfrq + "Hz";
				}
			}
			BlueTooth.btbusy = true;
			err = !BlueTooth.BTPutByte(SampleRateSet);
			err = !BlueTooth.BTPutByte(PixDiv);
			err = !BlueTooth.BTPutByte(nDiv);
			err = !BlueTooth.BTPutByte(Mag);
			err = !BlueTooth.BTPutByte(SubSampling);
			err = !BlueTooth.BTPutByte(Trigger);
			err = !BlueTooth.BTPutByte(Triple);
			err = !BlueTooth.BTPutByte(Auto);
			err = !BlueTooth.BTPutShort(TriggerLevel);
			err = !BlueTooth.BTPutShort(VPos);
			err = !BlueTooth.BTPutInt(TimeDiv);
			err = !BlueTooth.BTPutInt(SampleRate);

			n = (DDSWave.SCPXSIZE * 2 * 3) / 4;
			if (BlueTooth.BTGetBytes(n)) {
				i = 0;
				j = 0;
				while (i < DDSWave.SCPXSIZE) {
					f = BTToInt(j) & 0xFFFFFF;
					g = (f >> 12) & 0xFFF;
					f &= 0xFFF;
					DDSWave.scpWave[i] = (short)f;
					i++;
					DDSWave.scpWave[i] = (short)g;
					i++;
					j += 3;
				}
			}
			BlueTooth.btbusy = false;
			return s;
		} catch (Exception e) {
			return "err";
		}
	}

}
