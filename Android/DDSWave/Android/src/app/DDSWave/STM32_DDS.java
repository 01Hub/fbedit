package app.DDSWave;

public class STM32_DDS {
	public short DDS_Cmd;
	public short DDS_Wave;
	public int DDS__PhaseAdd;
	public int DDS_Amplitude;
	public int DDS_DCOffset;
	public short SWEEP_Mode = 0;
	public short SWEEP_Time = 0;
	public int SWEEP_Step = 0;
	public int SWEEP_Min = 0;
	public int SWEEP_Max = 0;

	public boolean SendDDS() {
		boolean err = false;
		try {
			if (BlueTooth.btconnected) {
				BlueTooth.btbusy = true;
				err = !BlueTooth.BTPutInt(BlueTooth.CMD_DDSSET);
				err |= !BlueTooth.BTPutShort(DDS_Cmd);
				err |= !BlueTooth.BTPutShort(DDS_Wave);
				err |= !BlueTooth.BTPutInt(DDS__PhaseAdd);
				err |= !BlueTooth.BTPutInt(DDS_Amplitude);
				err |= !BlueTooth.BTPutInt(DDS_DCOffset);
				err |= !BlueTooth.BTPutShort(SWEEP_Mode);
				err |= !BlueTooth.BTPutShort(SWEEP_Time);
				err |= !BlueTooth.BTPutInt(SWEEP_Step);
				err |= !BlueTooth.BTPutInt(SWEEP_Min);
				err |= !BlueTooth.BTPutInt(SWEEP_Max);
				BlueTooth.btbusy = false;
			}
			return !err;
		} catch (Exception e) {
			return false;
		}
	}
}
