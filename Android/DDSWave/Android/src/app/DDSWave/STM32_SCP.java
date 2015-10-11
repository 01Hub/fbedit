package app.DDSWave;

public class STM32_SCP {

	public int ADC_Prescaler = 0;
	public int ADC_TwoSamplingDelay = 0;
	public int ScopeTrigger = 1;
	public int ScopeTriggerLevel = (int)(13.65 * 150.0);
	public int ScopeTimeDiv = 15;
	public short ScopeVoltDiv = 8;
	public short ScopeMag = 0;
	public int ScopeVPos = (int)(13.65 * (150.0 + 13.0));
	public int ADC_TripleMode = 1;
	public int ADC_SampleTime = 0;
	public int ADC_SampleSize = 1252;
	public int fSubSampling = 0;

	public byte[] srset = {0x5F,0x57,0x4F,0x5E,0x5D,0x47,0x56,0x5C,0x55,0x4E,0x54,0x5B,0x4D,0x53,0x4C,0x5A,0x46,0x4B,0x45,0x52,0x59,0x44,0x51,0x3F,0x3E,0x3D,0x3C,0x3B,0x2F,0x2E,0x39,0x2D,0x38,0x2C,0x2B,0x2A,0x36,0x29,0x1F,0x28,0x1E,0x1D,0x1C,0x26,0x1B,0x1A,0x19,0x24,0x18,0x17,0x16,0x22,0x0F,0x0E,0x0D,0x0C,0x0B,0x0A,0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x02,0x01,0x00};
	public  short[] stset = {3,15,28,56,84,112,144,480};
	public String scpvdstr[] = {"1mV","2mV","5mV","10mV","20mV","50mV","100mV","200mV","500mV"};
//	public static short ADC_Tmp[] = new short[32 * 1024];
//	public static short SubSample[] = new short[2048];
//	public static short SubSampleCount[] = new short[2048];

    private static int BTToInt(int i) {
    	return (BlueTooth.btreadbuffer[i+2] & 0xFF) << 16 | (BlueTooth.btreadbuffer[i+1] & 0xFF) << 8 | (BlueTooth.btreadbuffer[i+0] & 0xFF);
    }

	public String SendSCP() {
		boolean err;
		int f, g, i, j;
		String s = "";
		try {
			BlueTooth.btbusy = true;
			err = !BlueTooth.BTPutInt(BlueTooth.CMD_SCPSET);
			if (BlueTooth.BTGetBytes(8)) {
				f = BlueTooth.BTToInt(4);
				if (f >= 1000000) {
					s = String.format("%.3f",((double)(f / 1000000.0))) + "MHz";
				} else if (f >= 1000) {
					s = String.format("%.3f",((double)(f / 1000.0))) + "KHz";
				} else {
					s = "" + f + "Hz";
				}
			}
			BlueTooth.btbusy = true;
			err |= !BlueTooth.BTPutInt(ADC_Prescaler);
			err |= !BlueTooth.BTPutInt(ADC_TwoSamplingDelay);
			err |= !BlueTooth.BTPutInt(ScopeTrigger);
			err |= !BlueTooth.BTPutInt(ScopeTriggerLevel);
			err |= !BlueTooth.BTPutInt(ScopeTimeDiv);
			err |= !BlueTooth.BTPutShort(ScopeVoltDiv);
			err |= !BlueTooth.BTPutShort(ScopeMag);
			err |= !BlueTooth.BTPutInt(ScopeVPos);
			err |= !BlueTooth.BTPutInt(ADC_TripleMode);
			err |= !BlueTooth.BTPutInt(ADC_SampleTime);
			err |= !BlueTooth.BTPutInt(ADC_SampleSize);
			err |= !BlueTooth.BTPutInt(fSubSampling);
			err |= !BlueTooth.BTGetBytes((ADC_SampleSize * 3)>>2);
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
			return s;
		} catch (Exception e) {
			return "err";
		}
	}

}
