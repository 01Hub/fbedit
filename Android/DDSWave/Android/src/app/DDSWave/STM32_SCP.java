package app.DDSWave;

public class STM32_SCP {

	public int ADC_Prescaler;
	public int ADC_TwoSamplingDelay;
	public int ScopeTrigger;
	public int ScopeTriggerLevel;
	public int ScopeTime;
	public short ScopeVoltDiv;
	public short ScopeMag;
	public int ScopeVPos;
	public int ADC_TripleMode;
	public int ADC_SampleTime;
	public int ADC_SampleSize;
	public int fSubSampling;

	public static short ADC_Data[] = new short[64 * 1024];
	public static short ADC_Tmp[] = new short[64 * 1024];
	public static short SubSample[] = new short[2048];
	public static short SubSampleCount[] = new short[2048];

	public boolean SendSCP() {
		boolean err;
		try {
			err = !BlueTooth.BTPutInt(BlueTooth.CMD_SCPSET);
			err |= !BlueTooth.BTPutInt(ADC_Prescaler);
			err |= !BlueTooth.BTPutInt(ADC_TwoSamplingDelay);
			err |= !BlueTooth.BTPutInt(ScopeTrigger);
			err |= !BlueTooth.BTPutInt(ScopeTriggerLevel);
			err |= !BlueTooth.BTPutInt(ScopeTime);
			err |= !BlueTooth.BTPutShort(ScopeVoltDiv);
			err |= !BlueTooth.BTPutShort(ScopeMag);
			err |= !BlueTooth.BTPutInt(ADC_TripleMode);
			err |= !BlueTooth.BTPutInt(ADC_SampleTime);
			err |= !BlueTooth.BTPutInt(ADC_SampleSize);
			err |= !BlueTooth.BTPutInt(fSubSampling);
			return !err;
		} catch (Exception e) {
			return false;
		}
	}

}
